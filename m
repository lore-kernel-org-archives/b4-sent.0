From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/3] SHIFT 6MQ SD-card support, improved responsivness of
 touchscreen, and codec
Date: Fri, 20 Mar 2026 17:29:04 +0100
Message-Id: <20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANB1vWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYyMD3cSK/Jz8khzd3MziZN0CQ10zA8MUEwuDZCPTlDQloK6CotS0zAq
 widGxtbUA1dZ+emEAAAA=
X-Change-ID: 20260320-axolotl-misc-p1-601d480c25df
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=752; i=david@ixit.cz;
 h=from:subject:message-id; bh=Ug1ZlH1itHQlZdElqdeD1isP56arF+w6CXvCerFsyC8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXXRcxjb8S5LRW8Pns7ES1MQJV59xBIt3G5V3
 POW24oXwmqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab110QAKCRBgAj/E00kg
 cuItEADFkkuZYtDhkdxfwf8AQjLxixHSPDF3FM9seYuJhTVHXMluvFfmDf4X6oWjpYhPv6GYrkq
 VhltG5hH+UNFpER1sE4gjnsiOJYepgWeh1HgswxMskYdOJQSlgicrnKhUjrCcfqMvuy3tnxWQmt
 cWcb1vHq5TJLnfNyPkLYjSW9UHt23uC2VpEB+Zw2eMN2zq8/NtJJWjpy2Ehc7XoLTKL+6LU8w/p
 69uHcBZPpjn+XmHTfssVC7a27p1UgrwCsB++JBkE2WusuWdIg3BtPPg3uDcOVrbV7iMMoIBuFdh
 y21wzDVmYCwZsfZ7osQKHGTpLvgXCbFqpffxhBeQqxNHQI5UxkWQu40wUiVVAgFMiuuPLDf1H/K
 3lWHVNmc8uTILEXvLkv12GXqUnrQnQYI3YIFcZ7jm3zU2PLoBxr2M8ZGWKkc/DmtG0trKEtqqyj
 rmqvBCuSkG7ej9C/DCLZ4fiswBO9r/37udralxgat0XSRjso9ugGMD3pgePaTBvVlgnIetH0YEd
 yRO3KrnAJpcYDgwiTMLL+2N+hNPGBAjY8c0kJ89xXXJ5zrD6w/zBjAdraUxVkWszgo17ylp0OkN
 GNWOUXmEkNeS4hhnu7lRmtsEDu+19DW3Qt0xlfctSYEARyWeVxtqQU0E5OcZ+0Dbj5vRDYI0I7O
 WX8dqDAq30gaVVw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I've tested that SD card and touchscreen works well, the codec does too,
but for complete enablement needs soundcard support which isn't fully
finished.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Alexander Martinz (1):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable TFA9890 codec

Casey Connolly (2):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable sdcard
      arm64: dts: qcom: sdm845-shift-axolotl: Set higher touchscreen i2c clock

 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 58 +++++++++++++++++++++++
 1 file changed, 58 insertions(+)
---
base-commit: 785f0eb2f85decbe7c1ef9ae922931f0194ffc2e
change-id: 20260320-axolotl-misc-p1-601d480c25df

Best regards,
-- 
David Heidelberg <david@ixit.cz>

