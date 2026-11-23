From: Stoicoci Mihaita <stoicoci.mihaita@gmail.com>
Date: Mon, 23 Nov 2026 22:54:03 +0200
Subject: [PATCH] arm64: dts: qcom: sm8250: Make the ADSP fastrpc remote
 heap no-map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-sm8250-fastrpc-remote-heap-no-map-v1-1-68ce6470e82c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOqnBGsC/yXNywrCMBCF4Vcps3YgifYSX0VcpHFqI+TCTBSh9
 N2Nujp8m/9sIMSBBM7dBkyvICGnBn3owK8u3QnDrRmMMoPW5ogSJ9MrXJxULh6ZYq6EK7mCKWN
 so/tB2Xk62XG00DqFaQnv38fl+rc85wf5+g3Dvn8A3JS6OoUAAAA=
X-Change-ID: 20261123-sm8250-fastrpc-remote-heap-no-map-15609b849779
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stoicoci Mihaita <stoicoci.mihaita@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795467242; l=2085;
 i=stoicoci.mihaita@gmail.com; s=20261123; h=from:subject:message-id;
 bh=VgzMi36Z50siaVxASdbNIrQSmm9qWWzg4SVyaAuqVHI=;
 b=6ctYusPoF2jBunbjDfr+/dJviQ2SO/k2DaeqdPTPcV16l9vtYBClJWpOIOyuWQxSI4QPOnb5Y
 y9SZG+LbUOSBYCMhECL8HBurSLymKNTOpo0U03H6E8alrM7ZtbEEVR5
X-Developer-Key: i=stoicoci.mihaita@gmail.com; a=ed25519;
 pk=IZ3PTCsOlRAC9RPQEB2Kk12DHzDz+pP3FWH8V6OqGto=
X-Endpoint-Received: by B4 Relay for stoicoci.mihaita@gmail.com/20261123 with auth_id=1623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADSP fastrpc node hands the whole adsp-rpc-remote-heap region to the
DSP when it probes: fastrpc_rpmsg_probe() calls qcom_scm_assign_mem()
with the qcom,vmids list (LPASS and ADSP_HEAP), which does not include
HLOS.

The region is declared reusable, so it is a CMA area and its pages are
still lent to movable allocations (page cache, anonymous memory). Under
memory pressure the kernel then touches pages that the hypervisor no
longer maps for HLOS. On a Lenovo Tab P12 Pro (TB-Q706F, SM8250) this
reset the device within a few minutes of heavy use (browser video,
Flatpak installs). Nothing reached the kernel log or pstore, the PMIC
reported a PS_HOLD reset, and the TZ diagnostic area showed a fatal SGI
on a different CPU each time just before the reset.

Mark the region no-map so it is never handed to the page allocator. With
this change the same workload ran with the CMA area fully used and no
reset.

Fixes: 531ce288b6dd ("arm64: dts: qcom: sm8250: Add memory-region for audio PD")
Signed-off-by: Stoicoci Mihaita <stoicoci.mihaita@gmail.com>
---
The same reusable remote heap without an HLOS VMID was added for other
SoCs as well (glymur, agatti, talos, kodiak, sm8750). I can only test
SM8250, so this patch changes sm8250.dtsi only.
---
 arch/arm64/boot/dts/qcom/sm8250.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8250.dtsi b/arch/arm64/boot/dts/qcom/sm8250.dtsi
index f975c2183..f415da478 100644
--- a/arch/arm64/boot/dts/qcom/sm8250.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250.dtsi
@@ -867,7 +867,7 @@ cdsp_secure_heap: memory@8bf00000 {
 		adsp_rpc_remote_heap_mem: adsp-rpc-remote-heap {
 			compatible = "shared-dma-pool";
 			alloc-ranges = <0x0 0x80000000 0x0 0x80000000>;
-			reusable;
+			no-map;
 			alignment = <0x0 0x400000>;
 			size = <0x0 0x800000>;
 		};

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-sm8250-fastrpc-remote-heap-no-map-15609b849779

Best regards,
--  
Stoicoci Mihaita <stoicoci.mihaita@gmail.com>

