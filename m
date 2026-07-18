From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 18 Jul 2026 19:06:32 +0200
Subject: [PATCH 4/5] usb: typec: mux: ps883x: add a delay after writing
 config regs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-ps883x-disable-usb4-v1-4-cec86d0b909e@oldschoolsolutions.biz>
References: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
In-Reply-To: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 stable@vger.kernel.org, "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784394390; l=814;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=JDRGNjZHwnE8crn2jnrOx4xrh9oKU1+eD++DjGnFB3U=;
 b=QJEqwTQRsu4EBX8jlmibp7oFM3RI5NyBNmyHadhxpVuBJWWiMVvO4fW2QRJ0jU9pI8Ec4y+lU
 PLZT5COM/mECJXCIXTIEVWVoL/6GW0dreW6Bu1HPrxvRCvu6mxcIe+E
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The config regs seem to need a few ms to propagate the changes through the
system (like, PLLs). This improves the hotplug dp altmode success rate
on the Lenovo 40B0 dock to 100%.

Tested with T14s G6 and 40B0 dock on the HDMI port with a type-c host cable.

Assisted-by: Gemini:3
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index 3533d4f363286..3ca2952e6a0a3 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -185,6 +185,8 @@ static int ps883x_configure(struct ps883x_retimer *retimer, int cfg0,
 		return ret;
 	}
 
+	usleep_range(20000, 30000);
+
 	return 0;
 }
 

-- 
2.53.0

