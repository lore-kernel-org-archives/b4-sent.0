From: David Heidelberg <david@ixit.cz>
Date: Mon, 16 Nov 2026 16:50:43 +0100
Subject: [PATCH v3 1/3] dt-bindings: remoteproc: qcom,msm8996-mss-pil:
 Document google,require-socinfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-modemsmem-v3-1-24ebc7ed6eb9@ixit.cz>
References: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
In-Reply-To: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Miro Mraz <mraz.miro@seznam.cz>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2146; i=david@ixit.cz;
 h=from:subject:message-id; bh=dCs1MzKn71TC5kAKQTc11AV3zsTZPlHuU7+NyOvVTSc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq+yZfrxNRyDKy8SjJi+RVA+BwJBXF+Ey6BInnV
 LyRqxF37M6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavsmXwAKCRBgAj/E00kg
 cuFtEACIgsmFbpk7AQG8NTu1bJUZ9BhYkOBOYhqOMUgMjmblG8GfVQ2UElxxD/oGJVD0pzkqLUs
 t/NZWd/+xQe7p4F6LrXTO7b7+8ypiMfeKoUh4RCcOBQ7k4oXkvYY62k/hQ64xJALH8NAQOCSw87
 en21mrrg4CL93CC9gdUUY8ic/pDJlvXCT97OJV9CJytcE1uFsfBC5kqKkD9kYyHcwnOaXuV5q4h
 BxW5pJsemtayIglZazZkwQ7C28LMSdgMSz2ErKBrj6cHl42IHtB8wVd48d/3klBq/5C6E72VOso
 ElVYxVWiz4XNV0wbSyA6b0wPTbb8tqXzBztYENFEftLz3nkvJ5bB8GeJ+3tu9aIKxnN4dvYhdHf
 eha0CvnZdD4YCPU2pp5I1IPKxyBQJsZgeBCkh6fr0e177bloUO5LmXvAOxgyYWxQGAVdF2odQLo
 ytWbP7p4Wz/clCgk6JzytRfghl19AbsXm1rO+zUGO/MHb4ZXfyouOhIpMDNBdRy3Lgh88tr9JLs
 n4RSiZzXf5H1jfW7sz3MxSHV1v0eFkbRrgAjMcrpU2H+6O16yMnTKYrzSVfZ8kCHP0bwI91P046
 ZzAyNod1BH4h0vEtaGpkFBd8GsYHMaDBTZA6gksq494sVvS8FCf+6ffG88VBXEPq3b18uaEvfHO
 0rmQkbX4nUfxCAw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modem firmware on Google Pixel boards (Pixel 3 through Pixel 5a)
expects the application processor to publish the SoC platform type,
subtype and revision in the first vendor-reserved SMEM item before the
modem is started. Represent that requirement as a boolean property on
the MSS remoteproc node so the MSS driver can publish the data before
booting the modem, instead of carrying a separate node and driver for
it.

This patch was written with assistance from a large language model.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/remoteproc/qcom,msm8996-mss-pil.yaml     | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/remoteproc/qcom,msm8996-mss-pil.yaml b/Documentation/devicetree/bindings/remoteproc/qcom,msm8996-mss-pil.yaml
index 4a1b439f985e3..ecc6782a92245 100644
--- a/Documentation/devicetree/bindings/remoteproc/qcom,msm8996-mss-pil.yaml
+++ b/Documentation/devicetree/bindings/remoteproc/qcom,msm8996-mss-pil.yaml
@@ -91,16 +91,25 @@ properties:
       - const: mss_restart
       - const: pdc_reset # only valid for qcom,sdm845-mss-pil
     minItems: 1
 
   qcom,qmp:
     $ref: /schemas/types.yaml#/definitions/phandle
     description: Reference to the AOSS side-channel message RAM.
 
+  google,require-socinfo:
+    type: boolean
+    description:
+      The modem firmware on Google Pixel boards (Pixel 3 through Pixel 5a)
+      expects the application processor to publish the SoC platform type,
+      subtype and revision in the first vendor-reserved SMEM item (item 134)
+      before the modem is started. When present, the MSS driver fills that
+      item from the socinfo SMEM data before booting the modem.
+
   qcom,smem-states:
     $ref: /schemas/types.yaml#/definitions/phandle-array
     description: States used by the AP to signal the Hexagon core
     items:
       - description: Stop modem
         items:
           - description: Phandle to the Shared Memory Point 2 Point or Shared
               Memory Manager device handling the communication with a remote

-- 
2.55.0

