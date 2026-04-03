From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:37 +0200
Subject: [PATCH WIP v3 08/11] Input: stmfts - add optional reset GPIO
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-8-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2354; i=david@ixit.cz;
 h=from:subject:message-id; bh=0H4tPbOaJAGUUm0gV1hJtlkmy5VinkfPf9XKlb62d/Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQW9t8Ua9CuM8zGK6neEShzwuW/HxqOtzx/
 WDfVNUFZyOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 clqPEACYGaJ7F2ne61ny7ICon2k6Kd28oYfIMioQqvdFM0jeIU8/qc23mpqUK9BteakDL9dz427
 Q2oU/6fVZrkY2eaX2TUpJShYuLpnd0i26mCvAY20J8nzLE9STuESYGkrvT52EMx3vAcK+NUH2Ls
 sjp6mNpXTCyUbAnhz7TEoSnln43BiEQpJ4Ho+lOyXvjGp7XytirLAksWti5kd2mF+MprhQMu027
 PnSNSHd+wjAge12lnYzsK3kkkOIkKUpNEVAeeScuc0ffZSo8DbktluAj491MU0UIBa72SkOa/cp
 DTPCSaQkvj3qR7LFuGO6Gac0kotIbjxGo+pGdCNl2Y5mAJYDw8V7Dgj7RGa/E7Lag28D8V7DlQ7
 oYN9wnAv7SNOw6Lg6wxPYqT3nLYwmt7dXo4N2ggTvmg/934c9D2LwQlERr+kzxMRsPvIHvw/53K
 ix9u6+IFsk/9K8tdz0jcnQRlo1miOPf4xLEGsVaCptad9GFvRYlLmv+YEg+ZUtTES/RB39SG/x8
 RnqW2iiyiltk6e4Jgu9lvYXww+18a2aZ6x+CQ57ZiI3xo6Tjl+r6iilqKG0UlXTI/S5Cj4HJ3Sk
 ru2ihmxrYwZrYAOcSQgqibKo9FayEoOXmTOXz5RZlrUexoMxy2FZhMtGbHekAnmaTxASFnnousA
 I8c0YzBRJ7GJkUw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Add support for an optional "reset-gpios" property. If present, the
driver drives the reset line high at probe time and releases it during
power-on, after the regulators have been enabled.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 5f7de5e687da2..04110006f54a0 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -77,6 +77,7 @@ static const struct regulator_bulk_data stmfts_supplies[] = {
 struct stmfts_data {
 	struct i2c_client *client;
 	struct input_dev *input;
+	struct gpio_desc *reset_gpio;
 	struct led_classdev led_cdev;
 	struct mutex mutex;
 
@@ -539,6 +540,15 @@ static int stmfts_read_system_info(struct stmfts_data *sdata)
 	return 0;
 }
 
+static void stmfts_reset(struct stmfts_data *sdata)
+{
+	gpiod_set_value_cansleep(sdata->reset_gpio, 1);
+	msleep(20);
+
+	gpiod_set_value_cansleep(sdata->reset_gpio, 0);
+	msleep(50);
+}
+
 static int stmfts_power_on(struct stmfts_data *sdata)
 {
 	int err;
@@ -548,6 +558,9 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	if (err)
 		return err;
 
+	if (sdata->reset_gpio)
+		stmfts_reset(sdata);
+
 	/*
 	 * The datasheet does not specify the power on time, but considering
 	 * that the reset time is < 10ms, I sleep 20ms to be sure
@@ -606,6 +619,10 @@ static void stmfts_power_off(void *data)
 	struct stmfts_data *sdata = data;
 
 	disable_irq(sdata->client->irq);
+
+	if (sdata->reset_gpio)
+		gpiod_set_value_cansleep(sdata->reset_gpio, 1);
+
 	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
 			       sdata->supplies);
 }
@@ -662,6 +679,12 @@ static int stmfts_probe(struct i2c_client *client)
 	if (err)
 		return err;
 
+	sdata->reset_gpio = devm_gpiod_get_optional(dev, "reset",
+						    GPIOD_OUT_HIGH);
+	if (IS_ERR(sdata->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(sdata->reset_gpio),
+				     "Failed to get GPIO 'reset'\n");
+
 	sdata->input = devm_input_allocate_device(dev);
 	if (!sdata->input)
 		return -ENOMEM;

-- 
2.53.0

