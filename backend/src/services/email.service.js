/**
 * Email Service
 * Sends verification emails, password reset links
 */
import nodemailer from 'nodemailer';
import env from '../config/env.js';
import logger from '../utils/logger.js';

class EmailService {
  constructor() {
    this.transporter = null;
    this._init();
  }

  _init() {
    // Only create transporter if SMTP is configured
    if (env.SMTP_USER && env.SMTP_PASS && !env.SMTP_USER.includes('your_')) {
      this.transporter = nodemailer.createTransport({
        host: env.SMTP_HOST,
        port: env.SMTP_PORT,
        secure: env.SMTP_PORT === 465,
        auth: {
          user: env.SMTP_USER,
          pass: env.SMTP_PASS,
        },
      });
    } else {
      logger.warn('⚠️  Email service not configured — emails will be logged to console');
    }
  }

  /**
   * Send email (or log in dev mode)
   */
  async _send(to, subject, html) {
    if (!this.transporter) {
      // Log email content in dev mode instead of sending
      logger.info(`📧 [DEV EMAIL] To: ${to} | Subject: ${subject}`);
      logger.debug(`📧 [DEV EMAIL] Body: ${html.substring(0, 200)}...`);
      return { messageId: 'dev-mode', accepted: [to] };
    }

    try {
      const result = await this.transporter.sendMail({
        from: `"KRX Analysis" <${env.SMTP_USER}>`,
        to,
        subject,
        html,
      });
      logger.info(`📧 Email sent to ${to}: ${result.messageId}`);
      return result;
    } catch (error) {
      logger.error(`❌ Failed to send email to ${to}:`, error);
      throw error;
    }
  }

  /**
   * Send email verification link
   */
  async sendVerificationEmail(email, name, token) {
    const verifyUrl = `${env.APP_URL}/verify-email?token=${token}`;
    const html = `
      <div style="max-width: 600px; margin: 0 auto; font-family: 'Inter', Arial, sans-serif; background: #0B0D17; color: #E8EAED; padding: 40px 24px; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 32px;">
          <h1 style="color: #3B82F6; font-size: 24px; margin: 0;">KRX Analysis</h1>
          <p style="color: #9CA3AF; font-size: 14px;">Korean Stock AI Analysis</p>
        </div>
        <h2 style="font-size: 20px; margin-bottom: 16px;">Verify your email</h2>
        <p style="color: #9CA3AF; line-height: 1.6;">Hi ${name},</p>
        <p style="color: #9CA3AF; line-height: 1.6;">Welcome to KRX Analysis! Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${verifyUrl}" style="display: inline-block; padding: 14px 32px; background: #3B82F6; color: white; text-decoration: none; border-radius: 12px; font-weight: 600; font-size: 16px;">
            Verify Email
          </a>
        </div>
        <p style="color: #6B7280; font-size: 12px;">This link expires in 24 hours. If you didn't create an account, ignore this email.</p>
      </div>
    `;
    return this._send(email, 'Verify your KRX Analysis account', html);
  }

  /**
   * Send password reset link
   */
  async sendPasswordResetEmail(email, name, token) {
    const resetUrl = `${env.APP_URL}/reset-password?token=${token}`;
    const html = `
      <div style="max-width: 600px; margin: 0 auto; font-family: 'Inter', Arial, sans-serif; background: #0B0D17; color: #E8EAED; padding: 40px 24px; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 32px;">
          <h1 style="color: #3B82F6; font-size: 24px; margin: 0;">KRX Analysis</h1>
        </div>
        <h2 style="font-size: 20px; margin-bottom: 16px;">Reset your password</h2>
        <p style="color: #9CA3AF; line-height: 1.6;">Hi ${name},</p>
        <p style="color: #9CA3AF; line-height: 1.6;">We received a password reset request. Click the button below to set a new password:</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${resetUrl}" style="display: inline-block; padding: 14px 32px; background: #3B82F6; color: white; text-decoration: none; border-radius: 12px; font-weight: 600; font-size: 16px;">
            Reset Password
          </a>
        </div>
        <p style="color: #6B7280; font-size: 12px;">This link expires in 1 hour. If you didn't request this, ignore this email.</p>
      </div>
    `;
    return this._send(email, 'Reset your KRX Analysis password', html);
  }
}

// Singleton
const emailService = new EmailService();
export default emailService;
