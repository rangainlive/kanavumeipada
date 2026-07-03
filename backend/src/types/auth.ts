export interface User {
  id: string;
  phone: string;
  email?: string;
  name?: string;
  avatarUrl?: string;
  examTarget?: string;
  state?: string;
  language: string;
  coinsBalance: number;
  xp: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface JWTPayload {
  userId: string;
  phone: string;
  iat: number;
  exp: number;
}

export interface PhoneOTPRequest {
  phone: string;
}

export interface VerifyOTPRequest {
  phone: string;
  otp: string;
}

export interface ProfileUpdateRequest {
  name: string;
  email?: string;
  examTarget: string;
  state: string;
  language?: string;
}

export interface AuthResponse {
  token: string;
  refreshToken: string;
  user: User;
}

export interface SignInResponse {
  message: string;
  requestId?: string;
}
