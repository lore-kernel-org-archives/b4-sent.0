From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Fri, 25 Nov 2022 09:34:44 -0500
Subject: [PATCH RESEND v10 1/2] arm64: defconfig: Enable devfreq cooling device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220825-test-endpoint-send-2-v10-1-d7d38aa7f65d@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v10-0-d7d38aa7f65d@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v10-0-d7d38aa7f65d@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.11.0-dev-87052
X-Developer-Signature: v=1; a=openpgp-sha256; l=867;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=ERbEPF09MMfHVzHEZdTfm0Y6nOjRabLJ3YyVAojq0P4=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIbLrUuV1ASmRK31mvJ4h3+mxqWBTyU6HARWrH/+9zd1Xui
 Hl4J7ihlYRDjYpAVU2Qp2xe7KajwoYdceo8pzBxWJpAhDFycAjARtiqGf/af7tfcd7W0Ci4+PklxTo
 9e/KLQnvX1Xzd+uOe7ya17kwDDP+Xtc5UWaK5gX71O5styP7kD9QaSPl9FGy3m3GE1fffbnBUA
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Clément Péron <peron.clem@gmail.com>

Devfreq cooling device framework is used in Panfrost
to throttle GPU in order to regulate its temperature.

Enable this driver for ARM64 SoC.

Signed-off-by: Clément Péron <peron.clem@gmail.com>
Acked-by: Jernej Skrabec <jernej.skrabec@gmail.com>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index d5b2d2dd4904..109004e44d21 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -584,6 +584,7 @@ CONFIG_SENSORS_INA2XX=m
 CONFIG_SENSORS_INA3221=m
 CONFIG_THERMAL_GOV_POWER_ALLOCATOR=y
 CONFIG_CPU_THERMAL=y
+CONFIG_DEVFREQ_THERMAL=y
 CONFIG_THERMAL_EMULATION=y
 CONFIG_IMX_SC_THERMAL=m
 CONFIG_IMX8MM_THERMAL=m

-- 
2.38.1-b4-0.11.0-dev-87052
