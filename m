From: David Heidelberg <david@ixit.cz>
Date: Thu, 23 Oct 2025 20:00:02 +0200
Subject: [PATCH] docs: dt-bindings: Extend the ordering list with a blank
 newline before status
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-docs-dt-newline-v1-1-1bf5e0040c0b@ixit.cz>
X-B4-Tracking: v=1; b=H4sIACFt+mgC/x3MQQqAIBBG4avErBswS4KuEi0qf2sgLDQqkO6et
 PwW7yWKCIJIXZEo4JIou8+oyoLmdfQLWGw2aaVNpXTNdp8j25M97k08uIXB1NQOylnK1RHg5Pm
 P/fC+H2hU5vVhAAAA
X-Change-ID: 20251023-docs-dt-newline-7e5eb43fe0fd
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1596; i=david@ixit.cz;
 h=from:subject:message-id; bh=jfI7bnd7GDYMrmutx004zTtdSqiNRLQra6bhxGa9W30=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo+m0hayS94Fa/yGgP2C6hYxl850hG0N03OmAlu
 WTyHv0eamWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPptIQAKCRBgAj/E00kg
 cvHwD/9RQmgpVxnghzO89wQCoUZ9+cq/4wSh9vOx9pOEcMjA/E/pNPQFHrHEsiPmCYuxCbZPLUh
 Yx9ZIazraG2YIMH7+CQ/z9POUrOaB/YI0rUPgDw1bTygfoF9n2YsxX38G5/zZWldVmWRwai1Xs3
 EICRYhv69zNZ+Cl3crXq8R5eXih0ge8xTvMpXoEtpESTHbi+ze5o6BKUi2iU9ETpCHpItbSLoCo
 tA8pV98T3LM1fNevPM3qXVrfdT0pVzAMia4kJZgBfF+DSbG0onXQz2bXdtwYFyennSlJm+/c9hH
 2vwGCR2ZkXW477YizfK++4388A7jPPw5PvgFlUwCwp5b1ht6fd21fRpCMViYVX7lo+W3KnQ3UcT
 hUhN92BstR0GsK4k7z5NcjF7Z3yXtjx7M0h8HBlFupqsoyrgTOViCXgD8oJRoRbI0GgPaK2qsxE
 +sO11M/lQqbOtd2sY6wwIfIyFN+R5P01E3TDl2TiTiySidLubI+saxbL7S6iREh38zcWbfSAy3l
 4C6FYjMt1KP4yQGxiqQuxHWDyXi9NqMm1dD4MIx3yars8avafdHvSVi8Eq4unor3MKxhqGKsnjo
 ML+BgkJZhBvSFEmS5iqXXZi9IxzNc+EjyuVCcoJOWuhbKhPXSZJEltgOwJ2e842P6kHJEslfuPu
 Xjb4rsWxC6jQ4dw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For better readability, it is recommended to insert a newline before the
'status' property. Adjust the examples accordingly.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/dts-coding-style.rst | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/dts-coding-style.rst b/Documentation/devicetree/bindings/dts-coding-style.rst
index 202acac0507ab..4a02ea60cbbe2 100644
--- a/Documentation/devicetree/bindings/dts-coding-style.rst
+++ b/Documentation/devicetree/bindings/dts-coding-style.rst
@@ -120,7 +120,8 @@ The following order of properties in device nodes is preferred:
 4. Standard/common properties (defined by common bindings, e.g. without
    vendor-prefixes)
 5. Vendor-specific properties
-6. "status" (if applicable)
+6. "status" (if applicable), preceded by a blank line if there is content
+   before the property
 7. Child nodes, where each node is preceded with a blank line
 
 The "status" property is by default "okay", thus it can be omitted.
@@ -150,6 +151,7 @@ Example::
 		#address-cells = <1>;
 		#size-cells = <1>;
 		vendor,custom-property = <2>;
+
 		status = "disabled";
 
 		child_node: child-class@100 {
@@ -165,6 +167,7 @@ Example::
 		vdd-1v8-supply = <&board_vreg4>;
 		vdd-3v3-supply = <&board_vreg2>;
 		vdd-12v-supply = <&board_vreg3>;
+
 		status = "okay";
 	}
 

---
base-commit: efb26a23ed5f5dc3554886ab398f559dcb1de96b
change-id: 20251023-docs-dt-newline-7e5eb43fe0fd

Best regards,
-- 
David Heidelberg <david@ixit.cz>

