From: Konstantin Ryabitsev <mricon@gmail.com>
Date: Thu, 01 Dec 2022 15:46:49 -0500
Subject: [PATCH RESEND v10 1/2] arm64: defconfig: Enable devfreq cooling device
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
Message-Id: <20220825-test-endpoint-send-2-v10-1-7be288f4f042@gmail.com>
References: <20220825-test-endpoint-send-2-v10-0-7be288f4f042@gmail.com>
In-Reply-To: <20220825-test-endpoint-send-2-v10-0-7be288f4f042@gmail.com>
To: =?utf-8?q?T=C3=A9sting_T=C3=A9st?= <mricon@kernel.org>
X-Mailer: b4 0.11.0-dev-6404c
X-Developer-Signature: v=1; a=openpgp-sha256; l=847; i=mricon@gmail.com;
 h=from:subject:message-id; bh=XeHDnwhIC2Pa++gn1fltBElJbM1iEI5GuLVmTjhWhJA=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJI7hfY9PDBhpSrThR3BM4Jai//rC5/JYvb57x3rlVjf7iNd
 zhvZUcrCIMbFICumyFK2L3ZTUOFDD7n0HlOYOaxMIEMYuDgFYCIyDQz/TMOqV82YVhpbqMHot/D1k+
 NfItqm7zcyufCB95u3jkR2OiNDw1uWx5UVJzJKN8WVaCWb/ZmZp3KGj3fx5xmpXC/tZp3mAAA=
X-Developer-Key: i=mricon@gmail.com; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for mricon@gmail.com/default with auth_id=10
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
2.38.1
