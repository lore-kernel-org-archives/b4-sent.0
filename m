From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Mon, 29 Aug 2022 13:49:17 -0400
Subject: [PATCH v3 1/4] arm64: defconfig: Enable devfreq cooling device
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v3-1-e29bfe9731e0@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v3-0-e29bfe9731e0@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v3-0-e29bfe9731e0@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-65ba7
X-Developer-Signature: v=1; a=openpgp-sha256; l=785;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=R5JeIyhEIAP6a72Z0Jts2SebK0ldE35uk/7rt6IzKJ0=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJJ5/iiXz8npTClYc6KFt5S/7Oirj54TlNPWv3rlXcwgIc1e
 NPFFRykLgxgXg6yYIkvZvthNQYUPPeTSe0xh5rAygQxh4OIUgIn8fc7wP3PKLpkJk/xuN0nFxV+TnF
 apt87qWa7etJ/fZrdKJ304pM3w3/W3Hft75dZr0it+97894We0ynXbsUTejQvqfesaxJlmMAMA
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
b4 0.10.0-dev-65ba7
