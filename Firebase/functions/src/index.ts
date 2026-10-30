import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { GoogleGenAI } from "@google/genai";
import { defineSecret } from "firebase-functions/params";


initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = getFirestore();
const auth = getAuth();
const ALLOWED_ROOTS = new Set(["posts", "users", "config"]);

const githubToken = defineSecret("PAWSOME_IMAGE_UPLOAD_TOKEN");
const GITHUB_REPO = "baldbuffalo/Pawsome-assets";

function requireImagePath(value: unknown): string {
  if (typeof value !== "string" || !value.trim()) throw new HttpsError("invalid-argument", "An image path is required.");
  const clean = value.trim().replace(/^\/+|\/+$/g, "");
  if (clean.length > 180 || clean.split("/").some((part) => !/^[A-Za-z0-9._-]+$/.test(part))) {
    throw new HttpsError("invalid-argument", "Invalid image path.");
  }
  return clean;
}

export const githubUploadImage = onCall(
  { secrets: [githubToken], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "You must be signed in.");

    const data = (request.data ?? {}) as Record<string, unknown>;
    const imageBase64 = typeof data.imageBase64 === "string" ? data.imageBase64.trim() : "";
    const mimeType = typeof data.mimeType === "string" ? data.mimeType.trim().toLowerCase() : "image/jpeg";
    const filename = requireImagePath(data.filename);
    const folder = requireImagePath(data.folder ?? "postImages");
    const path = folder + "/" + filename;

    if (!/^image\/(jpeg|jpg|png|webp)$/.test(mimeType)) {
      throw new HttpsError("invalid-argument", "Unsupported image type.");
    }
    if (!imageBase64 || !/^[A-Za-z0-9+/=]+$/.test(imageBase64)) {
      throw new HttpsError("invalid-argument", "Invalid image data.");
    }
    if (imageBase64.length > 14_000_000) {
      throw new HttpsError("invalid-argument", "Image is too large.");
    }

    const token = githubToken.value();
    const apiURL = `https://api.github.com/repos/${GITHUB_REPO}/contents/${path}`;
    const headers = {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "Content-Type": "application/json",
    };

    try {
      let sha: string | undefined;
      const existing = await fetch(apiURL, { headers });
      if (existing.ok) {
        const existingJSON = await existing.json() as { sha?: string };
        sha = existingJSON.sha;
      } else if (existing.status !== 404) {
        throw new Error(`GitHub lookup failed: HTTP ${existing.status}`);
      }

      const body: Record<string, string> = {
        message: typeof data.message === "string" && data.message.trim() ? data.message.trim() : `Upload ${filename}`,
        content: imageBase64,
      };
      if (sha) body.sha = sha;

      const response = await fetch(apiURL, {
        method: "PUT",
        headers,
        body: JSON.stringify(body),
      });
      const responseJSON = await response.json() as { message?: string; content?: { download_url?: string } };

      if (!response.ok) throw new Error(responseJSON.message || `GitHub upload failed: HTTP ${response.status}`);

      const downloadURL = responseJSON.content?.download_url;
      if (!downloadURL) throw new Error("GitHub returned no download URL.");

      return { downloadURL, path };
    } catch (error) {
      console.error("GitHub image upload failed", error);
      throw new HttpsError("internal", "GitHub image upload failed.");
    }
  },
);



function requireAdmin(request: CallableRequest<unknown>): void {
  if (!request.auth) throw new HttpsError("unauthenticated", "You must be signed in.");
  if (request.auth.token.admin !== true) throw new HttpsError("permission-denied", "Administrator access is required.");
}

function requireDocumentPath(path: unknown): string {
  if (typeof path !== "string" || path.trim().length === 0) throw new HttpsError("invalid-argument", "A Firestore document path is required.");
  const clean = path.trim().replace(/^\/+|\/+$/g, "");
  const parts = clean.split("/");
  if (parts.length % 2 !== 0 || parts.length > 12 || parts.some((part) => part === "" || part === "." || part === "..") || !ALLOWED_ROOTS.has(parts[0])) {
    throw new HttpsError("invalid-argument", "Path is not an allowed Pawsome document path.");
  }
  return clean;
}

function requireCollectionPath(path: unknown): string {
  if (typeof path !== "string" || path.trim().length === 0) throw new HttpsError("invalid-argument", "A Firestore collection path is required.");
  const clean = path.trim().replace(/^\/+|\/+$/g, "");
  const parts = clean.split("/");
  if (parts.length % 2 === 0 || parts.length > 11 || parts.some((part) => part === "" || part === "." || part === "..") || !ALLOWED_ROOTS.has(parts[0])) {
    throw new HttpsError("invalid-argument", "Collection is not available to the admin console.");
  }
  return clean;
}

function requireFields(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new HttpsError("invalid-argument", "fields must be an object.");
  return value as Record<string, unknown>;
}

function serialise(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (value && typeof value === "object") {
    const candidate = value as { toDate?: () => Date; path?: string };
    if (typeof candidate.toDate === "function") return candidate.toDate().toISOString();
    if (typeof candidate.path === "string") return { _type: "reference", path: candidate.path };
    if (Array.isArray(value)) return value.map(serialise);
    return Object.fromEntries(Object.entries(value).map(([key, nested]) => [key, serialise(nested)]));
  }
  return value;
}


export const detectCatBreed = onCall(
  { enforceAppCheck: true, timeoutSeconds: 60, memory: "512MiB" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "You must be signed in.");

    const data = (request.data ?? {}) as Record<string, unknown>;
    const imageBase64 = typeof data.imageBase64 === "string" ? data.imageBase64.trim() : "";
    const mimeType = typeof data.mimeType === "string" ? data.mimeType.trim().toLowerCase() : "image/jpeg";

    if (!imageBase64 || !/^[A-Za-z0-9+/=]+$/.test(imageBase64)) throw new HttpsError("invalid-argument", "An image is required.");
    if (!/^image\/(jpeg|jpg|png|webp)$/.test(mimeType)) {
      throw new HttpsError("invalid-argument", "Unsupported image type.");
    }
    if (imageBase64.length > 12_000_000) {
      throw new HttpsError("invalid-argument", "Image is too large.");
    }

    try {
      const ai = new GoogleGenAI({
        vertexai: true,
        project: "pawsome-90cb3",
        location: "global",
      });

      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: [
          { inlineData: { mimeType, data: imageBase64 } },
          {
            text: [
              "Determine whether the main subject of this image is a real domestic cat.",
              "Set isCat to true only when a cat is clearly visible as the main subject.",
              "Set isCat to false for dogs, other animals, people, objects, drawings, cartoons, screenshots, landscapes, empty images, or images where you cannot confidently verify a cat.",
              "If isCat is false, return an empty breed string.",
              "If isCat is true, identify the most specific cat breed supported by visible evidence.",
              "Use a standard/common breed name. If the breed cannot be determined reliably, use Domestic Shorthair only when that is visually justified; otherwise return an empty breed string.",
              "Do not guess and do not treat a merely cat-related object as a cat.",
            ].join(" "),
          },
        ],
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: {
              isCat: { type: "BOOLEAN", description: "True only if a real cat is clearly the main subject." },
              breed: { type: "STRING", description: "The identified cat breed, or an empty string when unknown or not a cat." },
            },
            required: ["isCat", "breed"],
          },
        },
      });

      const raw = response.text?.trim() ?? "";
      let result: { isCat?: unknown; breed?: unknown };
      try {
        result = JSON.parse(raw) as { isCat?: unknown; breed?: unknown };
      } catch {
        throw new Error("The vision model returned invalid JSON.");
      }

      const isCat = result.isCat === true;
      const breed = isCat && typeof result.breed === "string" ? result.breed.trim() : "";
      return { isCat, breed };
    } catch (error) {
      console.error("Cat image validation failed", error);
      throw new HttpsError("internal", "Could not verify that this is a cat. Please try another photo.");
    }
  },
);

export const adminListDocuments = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const collectionPath = requireCollectionPath(data.collectionPath);
  const limit = Math.min(Math.max(Number(data.limit ?? 100), 1), 100);
  const snapshot = await db.collection(collectionPath).limit(limit).get();
  return { documents: snapshot.docs.map((doc) => ({ path: doc.ref.path, fields: serialise(doc.data()) })) };
});

export const adminGetDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const path = requireDocumentPath(data.path);
  const doc = await db.doc(path).get();
  if (!doc.exists) throw new HttpsError("not-found", "Document not found.");
  return { path, fields: serialise(doc.data() ?? {}) };
});

export const adminCreateDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const collectionPath = requireCollectionPath(data.collectionPath);
  const fields = requireFields(data.fields);
  const ref = db.collection(collectionPath).doc();
  await ref.set({ ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: request.auth!.uid, createdAt: FieldValue.serverTimestamp() });
  return { ok: true, path: ref.path };
});

export const adminSetDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const fields = requireFields(data.fields);
  const rawPath = typeof data.path === "string" ? data.path.trim() : "";

  // The panel can create a new post without choosing an ID; Firestore generates it.
  if (rawPath === "posts") {
    const ref = db.collection("posts").doc();
    await ref.set({ ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: request.auth!.uid, createdAt: FieldValue.serverTimestamp() });
    return { ok: true, path: ref.path };
  }

  const path = requireDocumentPath(rawPath);
  const merge = data.merge !== false;
  await db.doc(path).set({ ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: request.auth!.uid }, { merge });
  return { ok: true, path };
});

export const adminDeleteDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const path = requireDocumentPath(data.path);
  await db.doc(path).delete();
  return { ok: true, path };
});

export const adminGetAppConfig = onCall(async (request) => {
  requireAdmin(request);
  const doc = await db.doc("config/app").get();
  return { fields: doc.exists ? serialise(doc.data() ?? {}) : {} };
});

export const adminSetAppConfig = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const fields = requireFields(data.fields);
  await db.doc("config/app").set({ ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: request.auth!.uid }, { merge: true });
  return { ok: true };
});

export const adminSetUserAdmin = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const uid = typeof data.uid === "string" ? data.uid.trim() : "";
  const enabled = data.admin === true;
  if (!uid) throw new HttpsError("invalid-argument", "A user UID is required.");
  if (uid === request.auth!.uid && !enabled) throw new HttpsError("failed-precondition", "You cannot remove your own administrator access.");

  const user = await auth.getUser(uid);
  const claims = { ...(user.customClaims ?? {}) } as Record<string, unknown>;
  if (enabled) claims.admin = true; else delete claims.admin;
  await auth.setCustomUserClaims(uid, claims);
  await db.doc(`users/${uid}`).set({ admin: enabled, updatedAt: FieldValue.serverTimestamp(), updatedBy: request.auth!.uid }, { merge: true });
  return { ok: true, uid, admin: enabled };
});

export const adminGetStats = onCall(async (request) => {
  requireAdmin(request);
  const [posts, users] = await Promise.all([db.collection("posts").count().get(), db.collection("users").count().get()]);
  return { posts: posts.data().count, users: users.data().count };
});
