const admin = require("firebase-admin");

// To use this, you need to download a serviceAccountKey.json from Firebase Console
// and place it in the same directory (or update the path).
// Make sure NOT to commit serviceAccountKey.json to git!
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

module.exports = admin;
