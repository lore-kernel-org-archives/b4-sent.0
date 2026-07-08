From: Sven Peter <sven@kernel.org>
Date: Wed, 08 Jul 2026 09:15:37 +0200
Subject: [PATCH RFC 1/6] dt-bindings: arm: psci: Add EFI conduit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-efi-psci-v1-1-9efb3abf0e4c@kernel.org>
References: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
In-Reply-To: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-efi@vger.kernel.org, 
 asahi@lists.linux.dev, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1948; i=sven@kernel.org;
 h=from:subject:message-id; bh=VWmWh6pzki/ShXejJu251uuQUSOrl8ApE+ih5NcCoSk=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ5bvT40an+LrNSsz3ou+eHBk0ZXtj533ymnX23xwvt15x
 YdfqJ65o5SFQYyLQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRg5qMDCvvckRZqXWc3Cb2
 W/IGc2WwDau3kNEPx6YTR8vSMlbsDGdkuPHeUvnjNHez9BTjI6zrxY8f0638FyfOeFRiqa7irW9
 LOAE=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple Silicon machines run the kernel in the highest available exception
level and can't trap to anything higher for PSCI calls. Instead, we will
add support for a conduit based on EFI runtime services to be able to
share the same level with the kernel itself.
Add the conduit to the bindings.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 Documentation/devicetree/bindings/arm/psci.yaml | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/psci.yaml b/Documentation/devicetree/bindings/arm/psci.yaml
index 6e2e0c551841..f9d607e1a213 100644
--- a/Documentation/devicetree/bindings/arm/psci.yaml
+++ b/Documentation/devicetree/bindings/arm/psci.yaml
@@ -28,6 +28,14 @@ description: |+
   Note that the immediate field of the trapping instruction must be set
   to #0.
 
+  Alternatively, when the "efi" method is used, the PSCI functions are not
+  invoked by trapping to a higher privilege level. Instead, they are backed
+  by EFI runtime services: the firmware exposes a PSCI handler that the OS
+  invokes through an EFI runtime call. This method is intended for platforms
+  where the kernel runs at the highest privilege level, leaving no higher level
+  to trap into; the firmware shares that same level and is instead reached
+  through EFI runtime services.
+
   [2] Power State Coordination Interface (PSCI) specification
     http://infocenter.arm.com/help/topic/com.arm.doc.den0022c/DEN0022C_Power_State_Coordination_Interface.pdf
 
@@ -69,6 +77,10 @@ properties:
       - smc
       # HVC #0, with the register assignments specified in this binding.
       - hvc
+      # The PSCI functions are implemented by EFI runtime services, and are
+      # invoked through a runtime call into the firmware rather than via an
+      # SMC or HVC trap.
+      - efi
 
   cpu_suspend:
     $ref: /schemas/types.yaml#/definitions/uint32

-- 
2.55.0

