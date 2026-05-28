From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 27 May 2026 20:39:28 -0700
Subject: [PATCH v2 1/3] dt-bindings: opp: Allow optional -vN suffix in
 opp-microvolt property name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-expressatt_cpufreq-v2-1-b9b7726ccb6d@gmail.com>
References: <20260527-expressatt_cpufreq-v2-0-b9b7726ccb6d@gmail.com>
In-Reply-To: <20260527-expressatt_cpufreq-v2-0-b9b7726ccb6d@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>, 
 Ilia Lin <ilia.lin@kernel.org>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779939570; l=1182;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=z/WcStOsVzdMFWp8uRFOe40/ecbf/NOss5Qfrb51yd8=;
 b=jftSPMYmys0+D6DQdiGgQPXjZmjbpCJ43RowmEacOFhKVXHINvYiKqyXVmVPmpdys0oFWSFLG
 KZ/LWB0W1CoAA7kuvyh7URIahwHeLXLrxfS7i0m1crvJLgfYUv0pfF/
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qcom-cpufreq-nvmem driver generates prop_name as
"speed%d-pvs%d-v%d" for Krait SoCs, resulting in property names like
opp-microvolt-speed0-pvs0-v0. The existing schema regex only allows
opp-microvolt-speed[0-9]+-pvs[0-9]+ without the trailing version
suffix.

Extend the regex to optionally match a -v[0-9]+ suffix so that
devicetrees using the full prop_name pass schema validation.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 Documentation/devicetree/bindings/opp/opp-v2-kryo-cpu.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/opp/opp-v2-kryo-cpu.yaml b/Documentation/devicetree/bindings/opp/opp-v2-kryo-cpu.yaml
index fd04d060c1de..846f49a99484 100644
--- a/Documentation/devicetree/bindings/opp/opp-v2-kryo-cpu.yaml
+++ b/Documentation/devicetree/bindings/opp/opp-v2-kryo-cpu.yaml
@@ -81,7 +81,7 @@ patternProperties:
       required-opps: true
 
     patternProperties:
-      '^opp-microvolt-speed[0-9]+-pvs[0-9]+$': true
+      '^opp-microvolt-speed[0-9]+-pvs[0-9]+(-v[0-9]+)?$': true
 
     required:
       - opp-hz

-- 
2.54.0

