export interface DecodedToken {
  exp: number; // seconds since epoch
  sub?: string;
  iat?: number;
  iss?: string;
  aud?: string | string[];
  [key: string]: unknown;
}

function base64UrlDecode(input: string): string {
  const base64 = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  try {
    return decodeURIComponent(
      atob(padded)
        .split('')
        .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
  } catch {
    return '';
  }
}

export function decodeJwt(token: string): DecodedToken | null {
  const parts = token.split('.');
  if (parts.length !== 3 || !parts[1]) return null;
  const payload = base64UrlDecode(parts[1]);
  try {
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

export function isTokenExpired(token: string, skewSeconds = 10): boolean {
  const decoded = decodeJwt(token);
  if (!decoded || !decoded.exp) return true;
  const now = Math.floor(Date.now() / 1000);
  return decoded.exp <= (now + skewSeconds);
}

export function getTokenRemainingSeconds(token: string): number | null {
  const decoded = decodeJwt(token);
  if (!decoded || !decoded.exp) return null;
  const now = Math.floor(Date.now() / 1000);
  return decoded.exp - now;
}
