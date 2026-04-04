import { MESSAGES } from '../constants/messages';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const validateEmail = (email: string): string | null => {
  if (!email) return MESSAGES.error.emailEmpty;
  if (!EMAIL_REGEX.test(email)) return MESSAGES.error.emailInvalidShort;
  return null;
};

export const validatePassword = (password: string): string | null => {
  if (!password) return MESSAGES.error.passwordEmpty;
  if (password.includes(' ')) return MESSAGES.error.passwordHasSpace;
  if (password.length < 6 || !/(?=.*[a-zA-Z])(?=.*[0-9])/.test(password)) {
    return MESSAGES.error.passwordWeak;
  }
  return null;
};
