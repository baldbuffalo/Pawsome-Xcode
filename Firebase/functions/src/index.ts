import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

const db = getFirestore();
const auth = getAuth();
const ALLOWED_ROOTS = new Set(["posts", "users", "config"]);

function requireAdmin(request: CallableRequest<unknown>): void {
  if (!request.auth) throw new HttpsError("unauthenticated", "You must be signed in.");
  if (request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
}

function requireDocumentPath(path: unknown): string {
  if (typeof path !== "string" || path.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A Firestore document path is required.");
  }
  const clean = path.trim().replace(/^\/+|\/+$/g, "");
  const parts = clean.split("/");
  if (
    parts.length % 2 !== 0 ||
    parts.length > 12 ||
    parts.some((part) => part === "" || part === "." || part === "..") ||
    !ALLOWED_ROOTS.has(parts[0])
  ) {
    throw new HttpsError("invalid-argument", "Path is not an allowed Pawsome document path.");
  }
  return clean;
}

function requireCollectionPath(path: unknown): string {
  if (typeof path !== "string" || path.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A Firestore collection path is required.");
  }
  const clean = path.trim().replace(/^\/+|\/+$/g, "");
  const parts = clean.split("/");
  if (parts.length % 2 === 0 || parts.length > 11 || parts.some((part) => part === "" || part === "." || part === "..")) {
    throw new HttpsError("invalid-argument", "Invalid Firestore collection path.");
  }
  if (!ALLOWED_ROOTS.has(parts[0])) {
    throw new HttpsError("permission-denied", "Collection is not available to the admin console.");
  }
  return clean;
}

function requireFields(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "fields must be an object.");
  }
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

export const adminListDocuments = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const collectionPath = requireCollectionPath(data.collectionPath);
  const limit = Math.min(Math.max(Number(data.limit ?? 100), 1), 100);
  const snapshot = await db.collection(collectionPath).limit(limit).get();
  return {
    documents: snapshot.docs.map((doc) => ({ path: doc.ref.path, fields: serialise(doc.data()) })),
  };
});

export const adminGetDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const path = requireDocumentPath(data.path);
  const doc = await db.doc(path).get();
  if (!doc.exists) throw new HttpsError("not-found", "Document not found.");
  return { path, fields: serialise(doc.data() ?? {}) };
});

export const adminSetDocument = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const path = requireDocumentPath(data.path);
  const fields = requireFields(data.fields);
  const merge = data.merge !== false;

  await db.doc(path).set(
    {
      ...fields,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth!.uid,
    },
    { merge },
  );

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
  await db.doc("config/app").set(
    {
      ...fields,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth!.uid,
    },
    { merge: true },
  );
  return { ok: true };
});

export const adminSetUserAdmin = onCall(async (request) => {
  requireAdmin(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const uid = typeof data.uid === "string" ? data.uid.trim() : "";
  const enabled = data.admin === true;
  if (!uid) throw new HttpsError("invalid-argument", "A user UID is required.");
  if (uid === request.auth!.uid && !enabled) {
    throw new HttpsError("failed-precondition", "You cannot remove your own administrator access.");
  }

  const user = await auth.getUser(uid);
  const claims = { ...(user.customClaims ?? {}), admin: enabled };
  if (!enabled) delete claims.admin;
  await auth.setCustomUserClaims(uid, claims);
  return { ok: true, uid, admin: enabled };
});

export const adminGetStats = onCall(async (request) => {
  requireAdmin(request);
  const [posts, users] = await Promise.all([
    db.collection("posts").count().get(),
    db.collection("users").count().get(),
  ]);
  return { posts: posts.data().count, users: users.data().count };
});
