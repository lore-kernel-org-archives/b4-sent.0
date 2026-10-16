From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 16 Oct 2026 22:13:50 +0200
Subject: [PATCH 1/2] pinctrl: qcom: sdm845: select the mux value per pin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-b4-sdm845-qupv3-s4-v1-1-672e9be21fd2@protonmail.com>
References: <20261016-b4-sdm845-qupv3-s4-v1-0-672e9be21fd2@protonmail.com>
In-Reply-To: <20261016-b4-sdm845-qupv3-s4-v1-0-672e9be21fd2@protonmail.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, David Wronek <david.wronek@mainlining.org>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792181640; l=2300;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=znIksOWrudNsp9MkPQ32uJ1zn0y6AypLxS2RN7WHhMc=;
 b=CJkvxcQ/ibNPMHY2cM5RN+tECGn8eLSm6TtHncTSb15Wo+jcep6AhfCAB11F+6agBwpRqWUsq
 XNcj74tmonDCbgAclepDhETPZImxdk+pfiYI2boGHMO/IkB3oIX8kDp
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The raw TLMM function value of an alternate function is not the same on
every pin.

On GPIO 89 "qup4" sits behind tsif1_clk (value 2), on GPIO 90..92 behind
two other functions (value 3).

Add a per-pin table for the functions in use and register the "qup4"
function for the QUP0 SE4 SPI pins (GPIO 89..92) next to "qup9".

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/pinctrl/qcom/pinctrl-sdm845.c | 45 +++++++++++++++++++++++++++++++----
 1 file changed, 40 insertions(+), 5 deletions(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-sdm845.c b/drivers/pinctrl/qcom/pinctrl-sdm845.c
index 24b42e94c7a..bfd412d8e34 100644
--- a/drivers/pinctrl/qcom/pinctrl-sdm845.c
+++ b/drivers/pinctrl/qcom/pinctrl-sdm845.c
@@ -18,9 +18,31 @@
 #define MAX_PIN_NAME_LEN 32
 static char pin_name[MAX_PIN_NAME_LEN] __section(".data");
 
+enum {
+	FUNC_QUP9,
+	FUNC_QUP4,
+	FUNC_GPIO,
+};
+
 static const struct pinctrl_function msm_pinctrl_functions[] = {
-	{"qup9", 1},
-	{"gpio", 0},
+	[FUNC_QUP9] = {"qup9", -1},
+	[FUNC_QUP4] = {"qup4", -1},
+	[FUNC_GPIO] = {"gpio", 0},
+};
+
+static const struct {
+	u8 pin;
+	u8 function;
+	u8 mux;
+} sdm845_pin_muxes[] = {
+	/* GPIO 4..5: UART9 debug console */
+	{ 4, FUNC_QUP9, 1 },
+	{ 5, FUNC_QUP9, 1 },
+	/* GPIO 89..92: GENI QUP0 SE4 SPI */
+	{ 89, FUNC_QUP4, 2 },
+	{ 90, FUNC_QUP4, 3 },
+	{ 91, FUNC_QUP4, 3 },
+	{ 92, FUNC_QUP4, 3 },
 };
 
 static const unsigned int sdm845_pin_offsets[] = {
@@ -80,10 +102,23 @@ static const char *sdm845_get_pin_name(struct udevice *dev,
 	return pin_name;
 }
 
-static int sdm845_get_function_mux(__maybe_unused unsigned int pin,
-				   unsigned int selector)
+static int sdm845_get_function_mux(unsigned int pin, unsigned int selector)
 {
-	return msm_pinctrl_functions[selector].val;
+	int i;
+
+	if (selector >= ARRAY_SIZE(msm_pinctrl_functions))
+		return -EINVAL;
+
+	if (selector == FUNC_GPIO)
+		return msm_pinctrl_functions[selector].val;
+
+	for (i = 0; i < ARRAY_SIZE(sdm845_pin_muxes); i++) {
+		if (sdm845_pin_muxes[i].pin == pin &&
+		    sdm845_pin_muxes[i].function == selector)
+			return sdm845_pin_muxes[i].mux;
+	}
+
+	return -EINVAL;
 }
 
 static const struct msm_pinctrl_data sdm845_data = {

-- 
2.55.0

