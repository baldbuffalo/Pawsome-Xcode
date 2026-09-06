import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

const db = getFirestore();

function requireAdmin(request: CallableRequest<unknown>): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

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

  // Firestore document paths must have an even number of segments.
  if (parts.length % 2 !== 0 || parts.length > 12 || parts.some((part) => part === "" || part === "." || part === "..")) {
    throw new HttpsError("invalid-argument", "Invalid Firestore document path.");
  }

  return clean;
}

function requireFields(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "fields must be an object.");
  }

  return value as Record<string, unknown>;
}

/**
 * Admin-only generic Firestore writer.
 *
 * This is the server-side foundation for a future Pawsome admin panel:
 * the panel can call this function instead of shipping database-editing
 * logic or hard-coded data changes inside the mobile apps.
 */
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

/** Admin-only Firestore document deletion. */
export const adminDeleteDocument = onCall(async (request) => {
  requireAdmin(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const path = requireDocumentPath(data.path);
  await db.doc(path).delete();

  return { ok: true, path };
});

/**
 * Stores app-wide settings in config/app.
 *
 * Existing app versions can listen to this document and react to settings
 * such as adsEnabled or maintenanceMode without requiring a store update.
 */
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
