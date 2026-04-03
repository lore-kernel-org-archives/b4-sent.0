From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:34 +0200
Subject: [PATCH WIP v3 05/11] Input: stmfts - disable regulators when power
 on fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-5-5da768cfd201@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1598; i=david@ixit.cz;
 h=from:subject:message-id; bh=LIButZg+Qr0VYxOivFVqKi0JBvx+GtP/QaYfETouW78=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQDRJtfGA8dK851nFa0dQ2JxBOUNYT4wkCr
 AFhPDC+8smJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 chRsD/4viI8uLlIse4j+WjF/Uq1x/n9t9g5nLR1KsGmY0DhwTdIBIuQmw8A9ImwhszZKGdkvp9l
 zmnv838m5M6RJkoPON0r40lybn8gqpnfj5m8ARTc6KPMLWU6TXDOq1TnEyOEe4hw108M8illqoz
 aIHkVowf54KSR1RVielpe2OVGn62cJaUXAYxwukiVR5TWBqJSW//S4vVhl3njlxteMy1/3UuFRB
 LRqQKsp0NsT+gE5e15nz8CT7I/ePTGRWHXAjZGwliX9Q8auG0XK353zzTZdByOc9hlPAHhXflRR
 o6QhQfzv8ZBNmVrqWORV8ylaLzMvgUP35aRQUNLUPwHTPb13v6mIVL1BgyvNYMHdKgpdwylKQTb
 FtVp7BvzWOohL6ZAOnElhUWs/68XwTh/hweYO5oGzDd5vXsm4QulPhMaRNuVec384gHW7hhyIxx
 OnnT/TJ9G/ZDjuZuEixwY3z1nOC+wBR7CxK2ATluQsXJGQtTznACmK5FI97hEtj3pERBAg7se9V
 uPnwfrcPf8PWAI/zKzfM3o6SP8FTv6PeJI+YCPTjjQKXhaRNpfYxhwPJeKWiyME3/ciS8iXt8RP
 JmMSYAVojQxXqBucqLcR7QxjqDqq+Ieoy5tCGWb3B+Fwf7ULEbO3mNg4eeGb7W2uLEk81zO4W+a
 RAOiIQYfrSrDGgg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We must power off regulators after failing at power on phase.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 71d9b747ccfc5..a90528b76f52b 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -557,7 +557,7 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_read_system_info(sdata);
 	if (err)
-		return err;
+		goto power_off;
 
 	enable_irq(sdata->client->irq);
 
@@ -565,11 +565,11 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_command(sdata, STMFTS_SYSTEM_RESET);
 	if (err)
-		return err;
+		goto power_off;
 
 	err = stmfts_command(sdata, STMFTS_SLEEP_OUT);
 	if (err)
-		return err;
+		goto power_off;
 
 	/* optional tuning */
 	err = stmfts_command(sdata, STMFTS_MS_CX_TUNING);
@@ -585,7 +585,7 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 
 	err = stmfts_command(sdata, STMFTS_FULL_FORCE_CALIBRATION);
 	if (err)
-		return err;
+		goto power_off;
 
 	/*
 	 * At this point no one is using the touchscreen
@@ -594,6 +594,11 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	(void) i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_IN);
 
 	return 0;
+
+power_off:
+	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies),
+			       sdata->supplies);
+	return err;
 }
 
 static void stmfts_power_off(void *data)

-- 
2.53.0

