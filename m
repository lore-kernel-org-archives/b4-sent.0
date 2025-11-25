From: David Heidelberg <david@ixit.cz>
Date: Tue, 25 Nov 2025 21:29:36 +0100
Subject: [PATCH v4 1/8] dt-bindings: arm: qcom: Add Pixel 3 and 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-pixel-3-v4-1-3b706f8dcc96@ixit.cz>
References: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
In-Reply-To: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
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
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>, Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=765; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vnt/xXHh7c01EXNWnpunAXvFyH2vLjx4UfYXxFc1+5w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJhGxIifGirp9T6Vi0DAyXs9lMbhdTd35xqlUn
 8qk+HAK3iuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSYRsQAKCRBgAj/E00kg
 cmSAD/42LNDykpTI8CUnBYJaoFIPJ7gr61SFUWX/wcGFaT6C2JmQl0ufk9mk4SJQf2+9+kQxajf
 zK6BKujBbQA5EB7w8XgHhtEcnptt28L68Lf+yhrVEroUc64+/QWg7xuOZ14uZLVZNkKt44xQSSY
 6Y8X5CmuyZdwIrIfPVAdRGxkdiVPqaR/Ezgu5m6997GfQfCXPQgRlOLGi8wbqIJlAsigon+1KZ3
 1rIhiZxBlPFllYSco5fi40JVVze0WjDgVTEghHS8cmOE75rMtwPGT9pnbGZJJBBLoZfBCkIBY96
 XJhHwb9pmqhVPW1a1i85npc9JOUtwLxf9vps0VZEdaJnMbiyZBYC0jj2FJJT/TApY0zYthispwp
 9cppO17ulPjPja9axlm7LuZrG3AXCzTlfQcvGO+iDWcSMs+y3pAjrfa0rOB8ZxBZmwt+6F1uuwd
 CvP9Rx16JKJbes/F1ICQCvV/CUo2+qqK+GRGHonjgHuOP5Gv13Wn2hu4KxubFARWqG2IcSaR4yt
 8WChH/9IlvmT2A7jQJGjAbYW9TiNd9qMD1kmlYVkx5nD5wIgmbb7BNt8Fr+hcT70TorQpeidVF1
 e0U9kwoVWhVOTGzLqZVb1PNyCYWaFGwBQlaQ2eeeFDvqyrgLtvZu1QN/C4skK/8hvYi6vNn+pxL
 ZgWZGycOSfdsf0Q==
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

