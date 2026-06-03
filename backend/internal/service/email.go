package service

import (
	"fmt"
	"math/rand"
	"time"

	"miku_music/config"

	gomail "gopkg.in/gomail.v2"
)

// EmailService 邮件发送服务
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

// SendVerificationCode 发送验证码邮件（MD3 视觉风格）
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

	// MD3 Light Theme 颜色变量定义
	// Primary: #006A6A (Miku Teal) | On-Primary: #FFFFFF | Surface: #F4FBFA | Surface Variant: #DAE5E4
	htmlBody := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: 'Roboto', system-ui, -apple-system, sans-serif; background-color: #F4FBFA; margin: 0; padding: 24px; color: #191C1C;">
  <table width="100%%" cellpadding="0" cellspacing="0" role="presentation">
    <tr>
      <td align="center">
        <!-- MD3 Card Container -->
        <table width="480" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #FFFFFF; border: 1px solid #C0C9C8; border-radius: 24px; overflow: hidden; padding: 32px 24px; box-shadow: 0px 1px 3px rgba(0, 0, 0, 0.05);">

          <!-- Header / Brand -->
          <tr>
            <td style="padding-bottom: 24px; text-align: center;">
              <div style="display: inline-block; font-size: 24px; font-weight: 700; color: #006A6A; letter-spacing: -0.5px;">
                Miku Music <span style="font-size: 20px;">🎵</span>
              </div>
              <div style="font-size: 14px; color: #404948; margin-top: 4px; font-weight: 500;">%s</div>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="border-top: 1px solid #DAE5E4; padding-top: 24px;">
              <p style="color: #191C1C; font-size: 16px; font-weight: 400; margin: 0 0 16px; line-height: 24px;">
                您的验证码是：
              </p>
            </td>
          </tr>

          <!-- MD3 Code Badge (Filled Variant) -->
          <tr>
            <td>
              <table width="100%%" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #CCE8E7; border-radius: 12px; text-align: center;">
                <tr>
                  <td style="padding: 16px 24px; font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #002020; font-family: 'Roboto Mono', 'SF Mono', monospace;">
                    %s
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Notice -->
          <tr>
            <td style="padding-top: 16px;">
              <p style="color: #404948; font-size: 14px; line-height: 20px; margin: 0;">
                验证码 <strong>10 分钟</strong>内有效。为了您的账号安全，请勿将此验证码转发给他人。
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding-top: 32px; text-align: center;">
              <p style="color: #707979; font-size: 12px; line-height: 16px; margin: 0; border-top: 1px solid #DAE5E4; padding-top: 16px;">
                此邮件由 Miku Music 系统自动发出，请勿直接回复。<br>
                &copy; 2026 Miku Music Project
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`, subject, body)

	// 纯文本备选
	plainBody := fmt.Sprintf("%s\n\n验证码: %s\n10分钟内有效\n\n— Miku Music", subject, body)

	// ── 使用 gomail 构建邮件 ──
	m := gomail.NewMessage()

	m.SetHeader("From", s.cfg.From)
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetHeader("X-Mailer", "Miku Music Server")

	m.SetBody("text/plain", plainBody)
	m.AddAlternative("text/html", htmlBody)

	port := 587
	if s.cfg.Port != "" {
		fmt.Sscanf(s.cfg.Port, "%d", &port)
	}

	d := gomail.NewDialer(s.cfg.Host, port, s.cfg.User, s.cfg.Password)

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
