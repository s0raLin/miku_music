package service

import (
	"fmt"
	"math/rand"
	"time"

	"miku_music/config"

	gomail "gopkg.in/gomail.v2"
)

// EmailService 邮件发送服务
//
// 使用 gomail 库构建 RFC 合规邮件，兼容 QQ邮箱/163/Gmail 等主流邮箱。
//
// 常用邮箱 SMTP 配置:
//
//	QQ邮箱:   Host=smtp.qq.com    Port=587  (需开启SMTP服务，使用授权码)
//	126邮箱:  Host=smtp.126.com   Port=465  (需开启SMTP服务，使用授权码)
//	163邮箱:  Host=smtp.163.com   Port=465  (需开启SMTP服务，使用授权码)
//	Gmail:    Host=smtp.gmail.com Port=587  (需开启两步验证+应用专用密码)
//
// 开发模式: SMTP_HOST 留空时不真实发送，仅打印验证码到控制台
type EmailService struct {
	cfg config.SMTPConfig
}

func NewEmailService(cfg config.SMTPConfig) *EmailService {
	return &EmailService{cfg: cfg}
}

// GenerateCode 生成6位数字验证码
func (s *EmailService) GenerateCode() string {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	code := rng.Intn(1000000)
	return fmt.Sprintf("%06d", code)
}

// SendVerificationCode 发送验证码邮件
//
// 使用 gomail 自动处理 TLS/STARTTLS、MIME multipart/alternative、
// Message-ID、Date 等标准头，避免 QQ邮箱 "缺少app字段" 的问题。
func (s *EmailService) SendVerificationCode(to, subject, body string) error {
	// ── 开发模式：未配置SMTP时仅打印 ──
	if s.cfg.Host == "" || s.cfg.User == "" {
		fmt.Printf("\n══════════════════════════════════════════\n")
		fmt.Printf("📧 [DEV模式] 验证码邮件\n")
		fmt.Printf("   收件人: %s\n", to)
		fmt.Printf("   主题:   %s\n", subject)
		fmt.Printf("   验证码: %s\n", body)
		fmt.Printf("══════════════════════════════════════════\n\n")
		return nil
	}

	// HTML 邮件正文
	htmlBody := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; margin: 0; padding: 20px;">
  <table width="100%%" cellpadding="0" cellspacing="0">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0" style="background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08);">
        <tr><td style="background: linear-gradient(135deg, #6366f1, #8b5cf6); padding: 32px 24px; text-align: center;">
          <h1 style="color: #fff; font-size: 24px; margin: 0;">Miku Music 🎵</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 14px;">%s</p>
        </td></tr>
        <tr><td style="padding: 32px 24px;">
          <p style="color: #374151; font-size: 15px; margin: 0 0 8px;">您的验证码是：</p>
          <p style="background: #f3f4f6; border-radius: 10px; padding: 16px 24px; text-align: center; font-size: 32px; font-weight: 700; letter-spacing: 6px; color: #6366f1; margin: 8px 0; font-family: 'SF Mono', 'Monaco', 'Menlo', monospace;">%s</p>
          <p style="color: #9ca3af; font-size: 13px; margin: 16px 0 0;">验证码 10 分钟内有效，请勿转发给他人。</p>
        </td></tr>
        <tr><td style="background: #f9fafb; padding: 16px 24px; text-align: center;">
          <p style="color: #9ca3af; font-size: 12px; margin: 0;">此邮件由 Miku Music 自动发送，请勿回复。</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`, subject, body)

	// 纯文本备选
	plainBody := fmt.Sprintf("%s\n\n验证码: %s\n10分钟内有效\n\n— Miku Music", subject, body)

	// ── 使用 gomail 构建邮件 ──
	m := gomail.NewMessage()

	// 设置标准邮件头（gomail 自动添加 Message-ID、Date、MIME-Version 等）
	m.SetHeader("From", s.cfg.From)
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetHeader("X-Mailer", "Miku Music Server") // 标识发件客户端

	// multipart/alternative: HTML + 纯文本
	m.SetBody("text/plain", plainBody)
	m.AddAlternative("text/html", htmlBody)

	// 配置 SMTP dialer
	port := 587
	if s.cfg.Port != "" {
		fmt.Sscanf(s.cfg.Port, "%d", &port)
	}

	d := gomail.NewDialer(s.cfg.Host, port, s.cfg.User, s.cfg.Password)

	// gomail 自动处理 TLS（STARTTLS on 587, direct TLS on 465）
	// 关闭证书验证仅用于开发环境，生产环境应移除
	// d.TLSConfig = &tls.Config{InsecureSkipVerify: true}

	if err := d.DialAndSend(m); err != nil {
		return fmt.Errorf("邮件发送失败: %w", err)
	}

	fmt.Printf("✅ 邮件已发送: %s → %s\n", s.cfg.From, to)
	return nil
}

// SendLoginCode 发送登录验证码
func (s *EmailService) SendLoginCode(toEmail, code string) error {
	subject := "登录验证码"
	return s.SendVerificationCode(toEmail, subject, code)
}

// SendRegisterCode 发送注册验证码
func (s *EmailService) SendRegisterCode(toEmail, code string) error {
	subject := "注册验证码"
	return s.SendVerificationCode(toEmail, subject, code)
}
