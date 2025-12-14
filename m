From: David Heidelberg <david@ixit.cz>
Date: Sun, 14 Dec 2025 15:51:17 +0100
Subject: [PATCH v7 1/8] dt-bindings: arm: qcom: Add Pixel 3 and 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251214-pixel-3-v7-1-b1c0cf6f224d@ixit.cz>
References: <20251214-pixel-3-v7-0-b1c0cf6f224d@ixit.cz>
In-Reply-To: <20251214-pixel-3-v7-0-b1c0cf6f224d@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Petr Hodina <phodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=765; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vnt/xXHh7c01EXNWnpunAXvFyH2vLjx4UfYXxFc1+5w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPs7pgp0W/ABUwFwmSK4XBPVArnh4jOPDAljuo
 bCKqZ7IfOKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT7O6QAKCRBgAj/E00kg
 cvrWEACZFsRcAcnuwWVSl/j6Y+FDxYSFS7U+eodnFNRMlp3dnCbPUKmKYKznYazg2AdRc3CtaCr
 UFtxmuyxPQIMfViqiIo+U0v9xWrpznYhf9lc5LUHqAV7Ggn3n/XGRgOoA07YQ9oDT27gxIDbAir
 aqTOV3FzSIZsRaBExGiHaE23Eq6K7R+QXr9HS18bAjsGD2LSLZ5yEz1MEIVxbg2u5XxrLyFkpi8
 9fFcEPlHq6aiAJVWyMoKJYQoAGu4QaZtmziIEHYpp4k8gP76ENSaypoOWfRXHMHOMKPUY3otGnG
 M4DuaID3HZLBtat0lRKxz3lIhKWIpAwpIif4JxKrpMS7VEelWVMmxHradOr9ZAwxpFd1hSjvLQO
 OTUv2F9Ztw3LOEQCK0fHTIopllRZGcVDfl9klkpzdwGEXbj9reAXdqeKpKJdm8JUUfNb4eVeS1e
 GBO13/t5BGokzP91ky0NFj1DzSUk6JY1KyjjltSOiDLFkX8+sg9SshqSlqS2KQS3gMJm241pfay
 +jquu8ivUBmF4yAwoc4trMClfEYD1J7GJb7CFFbRB77YU1oiWpn16i0NOIQ+35ON9/qymMM8R0L
 brHI+S+D+ate14e5ka04I68P4QAUFQ9RglYYrBv4J7KICxASmLdkjEaNbM45JDdS4jVGVuEaj6p
 Aphu0fPmsiV9CMQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Pixel 3 and 3 XL.

Acked-by: Krzysztof Kozlowski <krzk@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d84bd3bca2010..760b6633b7a55 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -900,6 +900,8 @@ properties:
 
       - items:
           - enum:
+              - google,blueline
+              - google,crosshatch
               - huawei,planck
               - lenovo,yoga-c630
               - lg,judyln

-- 
2.51.0

