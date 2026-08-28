# Firebase Windows

The Windows app in this repository is a C#/.NET application. Firebase does not provide an official first-party C# client Firestore SDK equivalent to the Android and Apple client SDKs used by Pawsome.

The current Windows implementation remains `Pawsome-Windows/Pawsome.Core/Firestore/FirestoreService.cs`, which uses the Firestore REST API with the signed-in user's Firebase ID token so Firestore Security Rules still apply.

When an official supported Windows/.NET client SDK is available for this client architecture, this adapter can be replaced without changing `Firebase/firestore.data.json` or the Firestore document contract.
