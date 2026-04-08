From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:51 +0200
Subject: [PATCH v4 08/11] Input: stmfts - add optional reset GPIO support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-8-64fe62027db5@ixit.cz>
References: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
In-Reply-To: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2312; i=david@ixit.cz;
 h=from:subject:message-id; bh=Oxezv3LVWvcy2a3O5okAfGZrVzhTs38AJC0Tf+JxgKo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOS1d0dXj0iC1bnB2PUOAopZm69S/9Tys0l2
 OabmP/9zpiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 cq4tD/9UxMKbKC9JdKOG/RwoIBh3Vxa1qrGkKMKNGVETPPjVe0qRqV9CZrtO5PUA2/wMgWabwqv
 9gCKoiUUNMtQeU1OQ2KMrE1dC5970Sqc6Bos4Z5fYXgWRRYAgsmb+TjUy1eVi7yaH5PWLPdSp3p
 cFRkmNnw9HcN8WF7hO2Gdnja0JZW7suYSRkmI2U+OYXzg2zPF7jcZ4oLmsWligdKOD96CM4hTlg
 HrD58ZCyJGR3ldncKB80ez/jAGud3LhSzsdehGDeSVqIHljSdcMI8smlpeRn4l34wCEzlgJlsRQ
 s37y00Hoi8gTYrAUHQt+q45pWUIe6NsMrWphr/dBt+snDeizP0Y91uXeeNJmDnp0F29rz13FQQG
 1o6RO3JW7kvveZrrZhjB54fFWtIMHlLdXnEqQxLxBB738pvbNOEww38g3ra5pfXXtCxgvowIL0a
 DQZPXsv4MG6PicmdS9r0RLeH0WHHqrwFYsVrehRO4Nd5mMJ7LnEtVSpTof8mvvpmPMm1UVc7Yhf
 KsY9xWEsG5eohoFg9XpUQJfFoj0NNNe8fiokWDt6jYswtnaA1D6ZyvmE2jtoOiGFh2zhsiQ4g+7
 KTcwakKTqhp8k9dKjzpQ4BeoU7FbrVcQBcZzveCKEHVh3YDjbzkvkAJj4x8qyK1v42Y6QxIPvrG
 jcUSG7Pr1w3fsxA==
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
index b61a19e954296..1e6d9a287cd0c 100644
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
 static int stmfts_configure(struct stmfts_data *sdata)
 {
 	int err;
@@ -599,6 +609,9 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	 */
 	msleep(20);
 
+	if (sdata->reset_gpio)
+		stmfts_reset(sdata);
+
 	err = stmfts_configure(sdata);
 	if (err)
 		regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
@@ -612,6 +625,10 @@ static void stmfts_power_off(void *data)
 	struct stmfts_data *sdata = data;
 
 	disable_irq(sdata->client->irq);
+
+	if (sdata->reset_gpio)
+		gpiod_set_value_cansleep(sdata->reset_gpio, 1);
+
 	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
 			       sdata->supplies);
 }
@@ -668,6 +685,12 @@ static int stmfts_probe(struct i2c_client *client)
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

