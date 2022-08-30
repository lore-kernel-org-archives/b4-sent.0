From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 30 Aug 2022 09:31:26 -0400
Subject: [PATCH RESEND v3 1/4] arm64: defconfig: Enable devfreq cooling device
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v3-1-736c986dd55c@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v3-0-736c986dd55c@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v3-0-736c986dd55c@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-bfc54
X-Developer-Signature: v=1; a=openpgp-sha256; l=785;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=FU4rpA5Zu6K7vHlXo8FyTKJHZMRZ3Jx8Kx1vK3vaEp4=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL5BHWjlSUO7uc83CC7JOZJSs/BjWwXqvsCHniHxGsUJ+4O
 ZKjsKGVhEONikBVTZCnbF7spqPChh1x6jynMHFYmkCEMXJwCMBHe6YwMnX8uPKyu/R3IqMu9PjbwvX
 P3lO7jbL9Wf1oqvuKM0sFQV0aGi/NVn2ox6QR6x93Z4+TiYJq3Y9HjpmyeF3Mbf5/5WNTLDwA=
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
b4 0.10.0-dev-bfc54
