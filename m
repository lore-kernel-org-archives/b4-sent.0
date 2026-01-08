From: David Heidelberg <david@ixit.cz>
Date: Thu, 08 Jan 2026 23:13:02 +0100
Subject: [PATCH v4 2/2] configs: Add google-pixel fragment config for Pixel
 3, 3 XL, 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-pixel-config-v4-2-76a2212b69a5@ixit.cz>
References: <20260108-pixel-config-v4-0-76a2212b69a5@ixit.cz>
In-Reply-To: <20260108-pixel-config-v4-0-76a2212b69a5@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de, Petr Vorel <petr.vorel@gmail.com>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, Simon Glass <sjg@chromium.org>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Matthew Croughan <matt@croughan.sh>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Simon Glass <simon.glass@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=969; i=david@ixit.cz;
 h=from:subject:message-id; bh=qCGWssl7AevuFwYko+wSdsMSFJKTaUJcKdPCvF9nMuA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpYCvtkv22Eohm2V3JBTpdP/7UB3Xxji5Zi0nqz
 iLmElFyZsSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWAr7QAKCRBgAj/E00kg
 ciOGD/9HqvrEANPQGbo27mqQqdson7R77BTJp2kLN6vO9Bfyu+OgJYgd+UHQ/fJG9XBhnp6/ciE
 KHGW1lUqFeg2OJrlk/lU3yH040t6tHMfWoPX2QBtO7xKq7qOCnYQaJpxiaM5OeYvw32oXTQWM7I
 9Arc9jmivRCUt+B+IqwdtB7v1009o76voXozElYucjhz+rM0zHQ4EJ4wR+oyZG/BDpVWIIOl881
 ofdnYvEEap9u2u3UJwbWIxNdVYNsN4JB5nINW0vI9QgXBd4dsf2J+X6wAzLGyjJIYd/WKpsoI8z
 K5vp6MnP36nDCe3rF3XgtBvB8mq4KK4PymjdOmuhuJ0JW+S8b21lvQJoN2nJLMHYQIIZF2jdbvP
 N12K42cr+BqoiVkxNc3OmXKzx+kZwd17MnabYSYIzUGYWQ3uYSREgLg3cUA6a/mnwd6l5FznC1q
 AKA0FSdAQCVMcxPHV8E/WvZzFsNjXiyNuF/uoToGq5jScLfWJCZiDrD6smitPybMTkuHSvvpt1l
 gY1/T9MhJAORu0DeDyKF/GW4afL0WiyUKRD7hkKBlwdTCcLub28Ghdb/6dNwOizoxa6xFWxK/QG
 hSCiDfDjEDkZMM5j+XwJ6vVuE/NR+MbovwJejWKF0evty8+jzDea1b2qSSSzkB+nSB3SbsdRj+d
 66Vowtd1R9g33Mw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a fragment config for the Pixel 3, Pixel 3 XL, Pixel 5.

On these devices, U-Boot is chainloaded via fastboot. However, due to
additional requirements added by Google, the image header must have
a specific value for the text offset.
This is solved by setting CONFIG_TEXT_BASE to 0x80080000 in U-Boot.

Reviewed-by: Simon Glass <simon.glass@canonical.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 board/qualcomm/google-pixel.config | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/board/qualcomm/google-pixel.config b/board/qualcomm/google-pixel.config
new file mode 100644
index 00000000000..999d4e45268
--- /dev/null
+++ b/board/qualcomm/google-pixel.config
@@ -0,0 +1,5 @@
+# Enables chainloading of U-Boot on Google Pixel phones using
+# newer bootloaders (Android Q/R)
+# Use for following devices: Pixel 3 (blueline), Pixel 3 XL (crosshatch),
+# Pixel 5 (redfin)...
+CONFIG_TEXT_BASE=0x80080000

-- 
2.51.0

