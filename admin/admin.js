import { initializeApp } from "https://www.gstatic.com/firebasejs/12.18.0/firebase-app.js";
import { getAuth, GoogleAuthProvider, onAuthStateChanged, signInWithPopup, signOut } from "https://www.gstatic.com/firebasejs/12.18.0/firebase-auth.js";
import { getFunctions, httpsCallable } from "https://www.gstatic.com/firebasejs/12.18.0/firebase-functions.js";

const firebaseConfig = {
  apiKey: "AIzaSyAtqr3lOWMQxkWmY1kSSmimkaMjeSoXUuo",
  authDomain: "pawsome-90cb3.firebaseapp.com",
  projectId: "pawsome-90cb3",
  storageBucket: "pawsome-90cb3.firebasestorage.app",
  messagingSenderId: "798924982333",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app, "europe-west1");
const provider = new GoogleAuthProvider();

const call = (name, data = {}) => httpsCallable(functions, name)(data).then(r => r.data);

const $ = id => document.getElementById(id);
const login = $("login");
const dashboard = $("dashboard");
const editorDialog = $("editorDialog");
const confirmDialog = $("confirmDialog");

let posts = [];
let users = [];
let appConfig = {};
let editingPath = null;
let deletingPath = null;

function showError(target, error) {
  target.textContent = error?.message || String(error);
  target.classList.remove("hidden");
}

function clearError(target) {
  target.textContent = "";
  target.classList.add("hidden");
}

function friendly(value) {
  if (value === null || value === undefined) return "";
  if (typeof value === "object" && typeof value.toDate === "function") return value.toDate().toISOString();
  return String(value);
}

function normalizeDoc(doc) {
  return { path: doc.path, fields: doc.fields || {} };
}

function field(doc, ...names) {
  for (const name of names) {
    if (doc.fields && doc.fields[name] !== undefined) return friendly(doc.fields[name]);
  }
  return "";
}

async function refresh() {
  try {
    const [postData, userData, configData, stats] = await Promise.all([
      call("adminListDocuments", { collectionPath: "posts", limit: 100 }),
      call("adminListDocuments", { collectionPath: "users", limit: 100 }),
      call("adminGetAppConfig"),
      call("adminGetStats"),
    ]);
    posts = (postData.documents || []).map(normalizeDoc);
    users = (userData.documents || []).map(normalizeDoc);
    appConfig = configData.fields || {};
    $("postCount").textContent = stats.posts ?? posts.length;
    $("userCount").textContent = stats.users ?? users.length;
    $("maintenanceState").textContent = appConfig.maintenanceMode ? "On" : "Off";
    $("adsState").textContent = appConfig.adsEnabled === false ? "Off" : "On";
    fillSettings();
    renderPosts();
    renderUsers();
  } catch (error) {
    console.error(error);
    alert(error?.message || "Could not refresh admin data.");
  }
}

function fillSettings() {
  $("maintenanceMode").checked = appConfig.maintenanceMode === true;
  $("adsEnabled").checked = appConfig.adsEnabled !== false;
  $("announcementTitle").value = appConfig.announcementTitle || "";
  $("announcementBody").value = appConfig.announcementBody || "";
}

function renderPosts() {
  const query = $("postSearch").value.trim().toLowerCase();
  const rows = posts.filter(p => JSON.stringify(p.fields).toLowerCase().includes(query)).map(p => {
    const status = field(p, "status", "Status") || "UNKNOWN";
    return `<tr><td><strong>${escapeHtml(field(p, "CatName", "catName") || "Untitled")}</strong><br><small>${escapeHtml(p.path.split("/").pop())}</small></td><td><span class="status-pill status-${escapeHtml(status)}">${escapeHtml(status)}</span></td><td>${escapeHtml(field(p, "location", "Location"))}</td><td>${escapeHtml(field(p, "Username", "username"))}</td><td><div class="action-row"><button data-edit="${escapeAttr(p.path)}">Edit</button><button class="delete" data-delete="${escapeAttr(p.path)}">Delete</button></div></td></tr>`;
  }).join("");
  $("postRows").innerHTML = rows;
  $("postEmpty").classList.toggle("hidden", rows.length !== 0);
}

function renderUsers() {
  const query = $("userSearch").value.trim().toLowerCase();
  const rows = users.filter(u => JSON.stringify(u.fields).toLowerCase().includes(query)).map(u => {
    const uid = u.path.split("/").pop();
    const isAdmin = u.fields.admin === true || u.fields.admin === "true";
    return `<tr><td><strong>${escapeHtml(field(u, "Username", "username") || "User")}</strong></td><td><code>${escapeHtml(field(u, "Email", "email") || uid)}</code></td><td>${escapeHtml(field(u, "JoinedOn", "createdAt", "joinedOn"))}</td><td>${isAdmin ? "✓ Admin" : "User"}</td><td><div class="action-row"><button data-edit="${escapeAttr(u.path)}">Edit</button><button data-admin="${escapeAttr(uid)}" data-value="${isAdmin ? "false" : "true"}">${isAdmin ? "Remove admin" : "Make admin"}</button></div></td></tr>`;
  }).join("");
  $("userRows").innerHTML = rows;
  $("userEmpty").classList.toggle("hidden", rows.length !== 0);
}

function escapeHtml(value) { return friendly(value).replace(/[&<>\"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c])); }
function escapeAttr(value) { return escapeHtml(value).replace(/'/g, "&#39;"); }

async function openEditor(path, initialFields = null) {
  clearError($("editorError"));
  editingPath = path;
  let fields = initialFields;
  if (!fields) {
    const result = await call("adminGetDocument", { path });
    fields = result.fields || {};
  }
  $("editorTitle").textContent = path ? "Edit document" : "New post";
  $("editorPath").textContent = path || "posts/<new document>";
  $("editorPathInput").value = path || "posts/<new document>";
  $("editorJson").value = JSON.stringify(fields, null, 2);
  editorDialog.showModal();
}

$("loginButton").addEventListener("click", async () => {
  clearError($("loginError"));
  try { await signInWithPopup(auth, provider); } catch (e) { showError($("loginError"), e); }
});
$("logoutButton").addEventListener("click", () => signOut(auth));
$("refreshButton").addEventListener("click", refresh);
$("postSearch").addEventListener("input", renderPosts);
$("userSearch").addEventListener("input", renderUsers);

for (const button of document.querySelectorAll(".tab")) {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach(b => b.classList.remove("active"));
    document.querySelectorAll(".tab-panel").forEach(p => p.classList.add("hidden"));
    button.classList.add("active");
    $("tab-" + button.dataset.tab).classList.remove("hidden");
  });
}

$("postRows").addEventListener("click", async e => {
  const edit = e.target.closest("[data-edit]");
  const del = e.target.closest("[data-delete]");
  if (edit) await openEditor(edit.dataset.edit);
  if (del) {
    deletingPath = del.dataset.delete;
    $("confirmText").textContent = deletingPath;
    confirmDialog.showModal();
  }
});

$("userRows").addEventListener("click", async e => {
  const edit = e.target.closest("[data-edit]");
  const admin = e.target.closest("[data-admin]");
  if (edit) await openEditor(edit.dataset.edit);
  if (admin) {
    try {
      await call("adminSetUserAdmin", { uid: admin.dataset.admin, admin: admin.dataset.value === "true" });
      await refresh();
    } catch (error) { alert(error?.message || "Could not update admin role."); }
  }
});

$("newPostButton").addEventListener("click", () => openEditor("", {
  CatName: "", CatAge: "", description: "", location: "", imageURL: "", likes: [], commentCount: 0, status: "LOST"
}));

$("editorForm").addEventListener("submit", async e => {
  e.preventDefault();
  clearError($("editorError"));
  try {
    const fields = JSON.parse($("editorJson").value);
    const result = await call("adminSetDocument", { path: editingPath || "posts", fields, merge: true });
    editorDialog.close();
    await refresh();
    if (!editingPath && result.path) await openEditor(result.path);
  } catch (error) {
    showError($("editorError"), error);
  }
});

$("confirmDelete").addEventListener("click", async e => {
  e.preventDefault();
  try { await call("adminDeleteDocument", { path: deletingPath }); confirmDialog.close(); await refresh(); }
  catch (error) { alert(error?.message || "Delete failed."); }
  finally { deletingPath = null; }
});

$("settingsForm").addEventListener("submit", async e => {
  e.preventDefault();
  $("settingsStatus").textContent = "Saving…";
  try {
    await call("adminSetAppConfig", { fields: {
      maintenanceMode: $("maintenanceMode").checked,
      adsEnabled: $("adsEnabled").checked,
      announcementTitle: $("announcementTitle").value.trim(),
      announcementBody: $("announcementBody").value.trim(),
    }});
    $("settingsStatus").textContent = "Saved to Firebase.";
    await refresh();
  } catch (error) { $("settingsStatus").textContent = error?.message || "Save failed."; }
});

onAuthStateChanged(auth, async user => {
  if (!user) {
    login.classList.remove("hidden"); dashboard.classList.add("hidden"); return;
  }
  try {
    const token = await user.getIdTokenResult(true);
    if (token.claims.admin !== true) {
      await signOut(auth);
      throw new Error("This account does not have administrator access.");
    }
    login.classList.add("hidden"); dashboard.classList.remove("hidden");
    $("accountText").textContent = user.email || user.displayName || user.uid;
    await refresh();
  } catch (error) {
    login.classList.remove("hidden"); dashboard.classList.add("hidden"); showError($("loginError"), error);
  }
});
