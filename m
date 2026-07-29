From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 29 Jul 2026 15:48:25 -0400
Subject: [PATCH 2/2] usb: typec: ucsi: ucsi_glink: Add compatible string
 for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-sm8475-pmic-glink-v1-2-c2e1967c04de@proton.me>
References: <20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me>
In-Reply-To: <20260729-sm8475-pmic-glink-v1-0-c2e1967c04de@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785354535; l=934;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=+6ks2/+OdDNHqyb0BrFzugSZ1v5//mlteIvw/LIgXIg=;
 b=bFtxRosoMKs1lORTnCjj6YLrrWGcMPeyGK3NziC+is5nHh6cDYakxFDXufZOIdPRLqmKLJD2k
 YlKmsf2ihBKB0WYamXqUbumZrtiNb8RI488EcU6Qjx3K6Ff6kwICwf7
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for pmic-glink.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/usb/typec/ucsi/ucsi_glink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_glink.c b/drivers/usb/typec/ucsi/ucsi_glink.c
index 12e07b9fe622..78a0ea349ed4 100644
--- a/drivers/usb/typec/ucsi/ucsi_glink.c
+++ b/drivers/usb/typec/ucsi/ucsi_glink.c
@@ -381,6 +381,7 @@ static const struct of_device_id pmic_glink_ucsi_of_quirks[] = {
 	{ .compatible = "qcom,sc8280xp-pmic-glink", .data = &quirk_sc8280xp, },
 	{ .compatible = "qcom,sm8350-pmic-glink", .data = &quirk_sc8180x, },
 	{ .compatible = "qcom,sm8450-pmic-glink", .data = &quirk_sm8450, },
+	{ .compatible = "qcom,sm8475-pmic-glink", .data = &quirk_sm8450, },
 	{ .compatible = "qcom,sm8550-pmic-glink", .data = &quirk_sm8450, },
 	{ .compatible = "qcom,x1e80100-pmic-glink", .data = &quirk_x1e80100, },
 	{}

-- 
2.55.0

