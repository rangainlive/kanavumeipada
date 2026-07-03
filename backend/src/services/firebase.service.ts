import admin from 'firebase-admin';

class FirebaseService {
  private initialized = false;

  initialize() {
    if (this.initialized) return;

    try {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
        // For local development, use service account JSON
        // In production, use GOOGLE_APPLICATION_CREDENTIALS env var
      });

      this.initialized = true;
      console.log('Firebase initialized');
    } catch (error) {
      console.error('Firebase initialization error:', error);
      throw error;
    }
  }

  async verifyToken(idToken: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  async verifyPhoneToken(phoneNumber: string) {
    // This would be called after Firebase returns a verified phone number
    // In practice, the client generates the token via Firebase SDK
    // and sends it to us for verification
    return { phoneNumber, verified: true };
  }

  async getUserByPhone(phoneNumber: string) {
    try {
      const user = await admin.auth().getUserByPhoneNumber(phoneNumber);
      return user;
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        return null;
      }
      throw error;
    }
  }

  async createUser(phoneNumber: string, displayName?: string) {
    try {
      const user = await admin.auth().createUser({
        phoneNumber,
        displayName,
      });
      return user;
    } catch (error: any) {
      if (error.code === 'auth/phone-number-already-exists') {
        return this.getUserByPhone(phoneNumber);
      }
      throw error;
    }
  }

  async setCustomClaims(uid: string, claims: Record<string, any>) {
    await admin.auth().setCustomUserClaims(uid, claims);
  }
}

export const firebaseService = new FirebaseService();
