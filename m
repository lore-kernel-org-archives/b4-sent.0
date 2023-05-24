From: Caleb Connolly <caleb.connolly@linaro.org>
Subject: [PATCH v8 0/2] power: supply: introduce support for the Qualcomm
 smb2 charger
Date: Wed, 24 May 2023 01:34:16 +0100
Message-Id: <20230524-pmi8998-charger-v8-0-b87ffcd9864d@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIhbbWQC/x2NQQqDMBBFryKz7rQhRjvpVUoXiRl1FqYyASmId
 zd2+Xj/8XcorMIFXs0OypsU+eYKdGtgmEOeGCVVBmtsazrrcF2EvCesVidWJGt8inF89o6gVjE
 UxqghD/PVlbSQ6x793WHi7RqsyqP8/pfvz3Gcd6ajroIAAAA=
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Caleb Connolly <caleb.connolly@linaro.org>, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, Tom Rix <trix@redhat.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.13-dev-1ec66
X-Developer-Signature: v=1; a=openpgp-sha256; l=1501;
 i=caleb.connolly@linaro.org; h=from:subject:message-id;
 bh=grr9x/N/VP19B6Af/fwQVdP70KTtMERFQJVJQj+7M+8=;
 b=owEBbQKS/ZANAwAIAQWDMSsZX2S2AcsmYgBkbVucI7lxOiqYKTm8CTAStsuPKFmnMs5YDsYN2
 FCaZZ6pnDqJAjMEAAEIAB0WIQS2UaFGPGq+0GkMVc0FgzErGV9ktgUCZG1bnAAKCRAFgzErGV9k
 tlt0D/4vqoWHEdygCZEXrnaFrUn9i8Isyqol2BP6/1tk6bqtYUisiD66UAhPsfg8JkpDXo/77YH
 5DHmG2vOtME1oIdDjGX1ejBLmI3eS7cbkIexEn0HyHwUbZimxiXy4vT4J+TX1Of+GJNMIJeDtSQ
 ydhsr29WFxPZDWsSvSjAB92H9ytAO8wjK0ing5/GRFmPe9dzAZoowZJBcm1N8OzDSJwqBj97Llf
 C5YXDIYXwQhbcvdPQsC8q2OUZ7HWdQ56toZ24rNheaiwFi6T06peDRNnKGAXpYZJspz37eoKOIm
 VXoOGZX1ljAnwolLH64y+Uv9Fj0mVVCXwTuOiEe6u65oBpWA+VziruGNAW9dhtA5F/IJNr7HU/K
 W9cKBtFSCENUDcCzUHeRDFYm7Fb4/REp85onez8mTUZ6C3H/ziwwI5AA4Bgtv8zDOc+xwt29ZBa
 w7UlzOIH/kioHG9QCowL1WS5P1eqx1m//yn/aTfruYSQN+z/iK18JXTFWRbRojaTdZICM0bt9q+
 RKvFqg5Bw28ziIennihC3JUgp6BPBVXyGYl3HhGEOIAB/sokaC6rvtGNLMQn6LsNjlH5da058LA
 ZMoU6iwwZ3cQujRtIs7VuY8y1uNCc1rK47FehW31iqLZN1Fqb8XzRrIXw3CcuKR+tv6g0hoN4Fd
 TXrcClheTEGkNDg==
X-Developer-Key: i=caleb.connolly@linaro.org; a=openpgp;
 fpr=83B24DA7FE145076BC38BB250CD904EB673A7C47
X-Endpoint-Received: by B4 Relay for caleb.connolly@linaro.org/default with auth_id=49
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the Qualcomm PMI8998/PM660 Switch-Mode Battery Charger.
This is the second generation SMB charger, and replaces the previous
SMBB hardware found in older PMICs.

Changes since v7:
 * Implement fixes suggested by Sebastian
 * Fix format warning
V7: https://lore.kernel.org/linux-arm-msm/20230127230506.3140297-1-caleb.connolly@linaro.org/

To: Sebastian Reichel <sre@kernel.org>
To: Rob Herring <robh+dt@kernel.org>
To: Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Caleb Connolly <caleb.connolly@linaro.org>
To: Andy Gross <agross@kernel.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konrad.dybcio@linaro.org>
To: Nathan Chancellor <nathan@kernel.org>
To: Nick Desaulniers <ndesaulniers@google.com>
To: Tom Rix <trix@redhat.com>

---
Caleb Connolly (2):
      dt-bindings: power: supply: qcom,pmi8998-charger: add bindings for smb2 driver
      power: supply: add Qualcomm PMI8998 SMB2 Charger driver

 .../power/supply/qcom,pmi8998-charger.yaml         |   82 ++
 drivers/power/supply/Kconfig                       |    9 +
 drivers/power/supply/Makefile                      |    1 +
 drivers/power/supply/qcom_pmi8998_charger.c        | 1059 ++++++++++++++++++++
 4 files changed, 1151 insertions(+)
---
base-commit: ac9a78681b921877518763ba0e89202254349d1b
change-id: 20230524-pmi8998-charger-8209dbbf7648

Best regards,
-- 
Caleb Connolly <caleb.connolly@linaro.org>

