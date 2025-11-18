From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:30:36 +0100
Subject: [PATCH v3 1/8] dt-bindings: arm: qcom: Add Pixel 3 and 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-pixel-3-v3-1-317a2b400d8a@ixit.cz>
References: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
In-Reply-To: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=716; i=david@ixit.cz;
 h=from:subject:message-id; bh=DlXm2VUp7Ijt8uTzaBaBxliSbXJ4DoxMqfa5a4LztB0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFjg6F+JThpLkjMmprBjtyfG75J8RRGnB/rUx
 kGMqVGVXCiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxY4AAKCRBgAj/E00kg
 cpqHEACHSQC5WpfNbxcU5X0hYKyjt7Ul+jRuZeBhkzzz6XKwM4qYp+xE4v0ETdr3CZ8Z06hW/tn
 cwS75DfyP78LRQ8qAbiM8/3fmqpJ1yzuZZEjnSiSfCfwS5pCzT2a1ZoIJOKpxUeviavE5tVsmTO
 pI5U5sYc2qosloveYRFK3AzsQ4R/56nLBmNDmWYC3WBzY6jhi4Uaj2kC2B6RDuqTJ6UedZNH4KS
 AnZrFssyGnmNt+XYUKUM7V/tVDT3PwqfL0Py43jN1IEHIK4WDRa6sLNDKt5RyVPe+5XetpyshOe
 xNZ+Z0fewLYMvRBHp/j3tcT1xB7QARyV133q1kZoKY+29SKPQXEd9u1oW+aLDAXKfNvcx6L1r2B
 WLiGT0Qr9O4rxf/HOc0qg3tWtQo6m8l8JeYnyx133IQAyDb5Bj6fA1tEeWXG91OKBz6AuM6q4FE
 Bhd2YGrIlehIdH0Ot9R2mLwIOPYK64JzTKzKPu3pGRiH7pYKpZZ9T6rrQdAIyetpzOu6njtNXKO
 A3IhcOnDM4U3xwGes4nP45NIU4/8tyGX9ctKvmGS5QaHwiEFccmaOiXM8dhqiKa7cD+aK7V/ErR
 MY6jjpVcCzillKZmqMBc+Gd+giJGB12InEkPkmRyGDZiCKJl2yHphsRMvV/o2SeOigxGeHKxax3
 i19bGPqfvX54HxQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Pixel 3 and 3 XL.

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

