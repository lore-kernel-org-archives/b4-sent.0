From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Recognize Snapdragon SDM850
Date: Sat, 27 Jun 2026 19:50:14 +0200
Message-Id: <20260627-sda850-v2-0-44bf46ade42e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFYNQGoC/2XMQQ6CMBCF4auQWTumLbRpXHkPwgI7o8wGTEsal
 PTuFrYu/5eXb4fEUTjBrdkhcpYky1zDXBoI0zi/GIVqg1HGKWdaTDR6q9A9bNDcdc6ZAPX8jvy
 U7YT6ofYkaV3i53SzPtY/ImvUSESeq+Et+btssl7DF4ZSyg+ZKh5kmgAAAA==
X-Change-ID: 20260623-sda850-6b5c1e44662c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=766; i=david@ixit.cz;
 h=from:subject:message-id; bh=I3bvbarQGG1JG360vnVYjew40hnVIm2x4NllJX1eEF8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqQA1YK8glQipsbPDu59baTNOyWXpD07/knJtmu
 1MsIYw1FFqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakANWAAKCRBgAj/E00kg
 cghdEAC3bJd1iiMqAS4n+igQBHlJZI6soKc3516kYlKVnjZjAS6lTiFzcRyjs5Q2tlv71lyybdw
 8a6eh4b8oKwocHHvgkJtpQKIU3UatIi7qUNwqrVXDJQ0XxQHvHa8AvlscO3qseB/b8XRmY5JuMf
 CkHzbkfdXpEP3dB1b6xlxHbhiHWmMQ+tE7gMxUXVgiuXdi3wjWMJD2T7Hy8AsNk0mjUI9oxe2zZ
 rCPQACacNgu9ufz1KkbyKjHCUfq3EZKuAM2happ7qGBKLjsbyywZIzRqkBoKFlfVngfHhHV7SLH
 xkeliIp1PURR4huylAXI5kcLzA+VTy4WOjbjlKuIlFuTArT2tkj8lA2nFJvjOPBV6XchzC5pmJf
 dV7xn8Q3ntyqWO6LUXlZPTTC3L2DAiRuimMLZeqZfLJS5thZYAlJYketE3EJ8wqQHLssm3BQRtW
 mWUyGF4IHIHUOCIo7kLrTuajEjrXYwhpD98BYy25fClteKTKoT3y17RcgKaCfjcDa/jE3WBCSz4
 seKvgG7vB0asSR72ttZfQRDnA26WHlMDafMOYktOcvofpNaqVFLj6HiEARSo7aw6/v8+KNfwIDP
 nBPYZUPidt0rkqnbgCQQoh2iN3efM+sg/xGmekgCvqSrpE/dpZAKropGCdlZkrRxXfryfUCN7h0
 PQDKiKARvKHRVnQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Useful for sdm850 devices in tree and also will be used by Comma AI comma three

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- It's not SDA850, but classic SDM850. (Konrad)
- Add consumer of the define (socinfo). (Krzysztof)
- Link to v1: https://lore.kernel.org/r/20260623-sda850-v1-1-ddd8e62c85d8@ixit.cz

---
David Heidelberg (2):
      dt-bindings: arm: qcom,ids: Add SoC ID for Snapdragon SDM 850
      soc: qcom: socinfo: Add SoC ID for SDM850

 drivers/soc/qcom/socinfo.c         | 1 +
 include/dt-bindings/arm/qcom,ids.h | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: 948efecf22e49aa4bf55bb73ec79a0ddcfd38571
change-id: 20260623-sda850-6b5c1e44662c

Best regards,
-- 
David Heidelberg <david@ixit.cz>

