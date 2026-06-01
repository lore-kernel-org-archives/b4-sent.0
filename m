From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Subject: [PATCH v3 0/3] Add support and enable the debug UART in the Pixel
 3a and Pixel 3a XL
Date: Mon, 01 Jun 2026 18:53:59 +0200
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/53OQY7CMAwF0KugrMcopC0UVtwDsXAStwSGpDhpR
 YV6d1IYaTaskFffsvz+Q0RiR1HsFg/BNLjogs+h+FkIc0LfEjibs1BSrWWhauhQ/4Yxj4sJwZL
 uW+iREwQPbNHgiB483ROst2pTFlVtqClF/tcxNe7+sg7Hd469PpNJM/B3wXTrc4n0f3bKUODx1
 XBYzdtvygwrkCA16qaqSzRW77sQ0xX5QinEZeBWzNigvgZUBqoCtd1aXTcSPwDTND0B6ipNr3E
 BAAA=
X-Change-ID: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1319;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=O2pCDokgZ3DXKuGnRSIwijCq5J/0NOJdQ50dy8sFUeM=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbk0nlT9oDrwgIlS4Y8YvL9kz9oommsGrD8Cy
 xFZLzZ48T+JAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25NAAKCRB6NCVl/2Nf
 eTDJD/0dbwV6sH9Y4IDn/C58x2AbIlbHOyIbWiquQWksdrJobyk9zXRzmEVi4D9BwZM7ey5CGKY
 DbP6TXb20djN5rpTJzB+j3Gq6mtR8QMJQHZWH6gDh51JOwcpeqNejp4X4A12bC068PuRxpGTshm
 QOCc2jiq42Ei5c4iBPqCTDDbIImUUS9J1LISI/Zxj5qn/3gOYHb8FA+O4QYtJE8IvRkM4kziaDs
 6NHv7/hypRuBkPpgQVRIGsep4TwkFYitUvqj1WdAdARaIQFm1nWdXMhZzqZzBQgfzvSO0rD5usx
 OuoktzkB9MhZTcSVQ41fUnDLAyOG4DNlace8XeMBIn7B6nfSIzLbdNXGvg0vpEHxE5GvxV73Vdk
 XKnHSnuAykIHqtyGTAyIPafz5b8SoZKT9zIEUXLpV8KPkv6B6REHKLr4Ob71QrNAOGN7EwFTmPB
 o5iR7pe5HAULyqWuhO93sE72DJL1EBhGG8UlpjxYdcyIo4NyRbuEtJJCkAlr4Jse8JiYtSf7x01
 qdTFOFuulYZOapQYWWwUVKe/CVEQ0Ni14MQOinfDQI55neltcZf/VPyoIENcyujU+K6FjDU7t3Z
 7eEyhnQBk2xgUacnSCxFO8JhIUrv91owZM9t3w4RUdrGMogvX9n9st1ghfvszGMg60tcO3PtXVt
 n4YhrAEr29b0w2w==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to get logs through the SBU pins in Google Pixel devices, it is
necessary to add support to the devicetree, and enable the corresponding
UART. With this code and an USB-Cereal board, I was able to get full kernel
logs through serial.

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
Changes in v3:
- Drop dependency on already-picked patches
- Link to v2: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org

Changes in v2:
- Fix typo in (3/3) commit message
- Link to v1: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org

---
Pablo Correa Gómez (3):
      arm64: dts: qcom: sdm670: add default uart pinctrl nodes
      arm64: dts: qcom: sdm670: add debug uart soc node
      arm64: dts: qcom: sdm670-google-common: enable debug uart

 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  18 +-
 arch/arm64/boot/dts/qcom/sdm670.dtsi               | 207 +++++++++++++++++++++
 2 files changed, 224 insertions(+), 1 deletion(-)
---
base-commit: be0cd82a9f584e562b243684303054134c8f6583
change-id: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4

Best regards,
--  
Pablo Correa Gómez <pabloyoyoista@postmarketos.org>

