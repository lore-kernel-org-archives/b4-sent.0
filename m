From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 02:21:46 +0100
Subject: [PATCH 1/3] media: dt-bindings: mipi-ccs: Allow 90 and 270 deg
 rotation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-op6-upstream-cameras-v1-1-234fb3b7bb18@ixit.cz>
References: <20261123-op6-upstream-cameras-v1-0-234fb3b7bb18@ixit.cz>
In-Reply-To: <20261123-op6-upstream-cameras-v1-0-234fb3b7bb18@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1238; i=david@ixit.cz;
 h=from:subject:message-id; bh=YSUwepiSqoDBtH0gFw4KuC+ySgKsZDWDkOBfiJm5ygk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA5UvX/SGAmXo0JT1pG6AU93lHHgkXbdX/cFu1
 Z/7eHbu23qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawOVLwAKCRBgAj/E00kg
 cuauD/957XAku1JmXT8/JIRZ7RCPQLy2QmCNk9ti/ZOfy3pSPdPPKCYGG012UlwuBiHOStfCZBJ
 46ZsNjekrayuExMp64gMbhHOduU6iovOu0xv2lcsYCO07xQ4pb7atAnc/tCH/MQaGqhTt+dQMu+
 fRhL74yNvaWUr5KKWNtM3kjl17e0qDDNrKPYRFMoXpCR7kXkv/pO1YUs7lGbNUy+uFGCNDeAjMy
 FOjbsb9T8Mje87A2NQn8o5CssOWz4CVJjMrnea5ZuZ6fIUYcrZpfP9znlMaZyqlY4dVl0KoTrIz
 6hbdyJXn7aw+d/1BpF9mYpoKgVUazsZ30EeOyM20E1xgWSG1LPNbRW+RCn74x5i40AhHKvA2VLp
 99EyqCxDz5YxiBX4K/eFUgP22mgiTb1x6UGyXikZSQBzwqj5LirVdoWihyg5DUQckMdPG1098xH
 sywlQ5oKa50qSa7HQVSPl9IHnxo9KvIHv9K3jgOQuTmmOBC8HWxLkZD9rTrms82oU0h/3BejZdj
 OXz1kv43IAHctA1luk13svQNlL0O9U7j7pC07wLVyTVCpleL3w12LIeC7kq0gggq5hesDZjxEqv
 mM86STPj8YAi8oY3ISg17kq0HbSHWSb/qEwW7aHQf3ynN06tRAA9IrbJF/veLvvAMqTFvxiIjjC
 Ugh3oCoIFn5Gp2g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Driver works with it without any issue.
Also allow orientation

Fixes: 72aa1c5f1d0f ("media: dt-bindings: mipi-ccs: Refer to video-interface-devices.yaml")
Fixes: 72051783cd73 ("media: dt-bindings: nokia,smia: Amend SMIA bindings with MIPI CCS support")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml b/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
index 217b08c8cbbd3..44faa2f613f37 100644
--- a/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
@@ -59,19 +59,18 @@ properties:
 
   reset-gpios:
     description: Reset GPIO. Also commonly called XSHUTDOWN in hardware
       documentation.
     maxItems: 1
 
   flash-leds: true
   lens-focus: true
-
-  rotation:
-    enum: [ 0, 180 ]
+  orientation: true
+  rotation: true
 
   port:
     $ref: /schemas/graph.yaml#/$defs/port-base
     additionalProperties: false
 
     properties:
       endpoint:
         $ref: /schemas/media/video-interfaces.yaml#

-- 
2.55.0

