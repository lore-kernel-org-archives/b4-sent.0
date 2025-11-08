From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:38:04 +0700
Subject: [PATCH v6 08/12] arm: dts: rockchip: rk356x: Prerelocate VOP in
 U-Boot proper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-8-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=566;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=5I30AlGYVLKJp+oQjDrislkk86yMIEw46an0SuM8cSY=;
 b=ZFsaj5B/5KdIYDVNubYZ4NBkx8o4HXGH2rWDz4uK0YTNy10jQEG/0j7d4wUhCtoP5JW5Emih2
 DK9mwHFZyKtCUfstOMSlSMKV3U2xeT2Jcfh2tkzA4W8nK8W+k9kQzAP
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to prerelocate VOP2 memory so the driver can work. This
will only support U-Boot proper.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/dts/rk356x-u-boot.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/dts/rk356x-u-boot.dtsi b/arch/arm/dts/rk356x-u-boot.dtsi
index 738b9673d35..1ed06239f05 100644
--- a/arch/arm/dts/rk356x-u-boot.dtsi
+++ b/arch/arm/dts/rk356x-u-boot.dtsi
@@ -170,6 +170,10 @@
 	bootph-all;
 };
 
+&vop {
+	bootph-some-ram;
+};
+
 &xin24m {
 	bootph-all;
 };

-- 
2.51.2

