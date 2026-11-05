From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 23:34:55 +0000
Subject: [PATCH RFC] KVM: arm64: Document that overlapping MEM_SHARE and
 MEM_UNSHARE are unordered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-mem-share-unshare-v1-1-e4c7d12d5d1d@cs.columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNT3dzUXN3ijMSiVN3SPAhtYWSSbGSWbJScYpCkBNRXUJSallkBNjN
 aKcjNWSm2thYALP9kbWgAAAA=
X-Change-ID: 20261105-mem-share-unshare-824c26c2cd0b
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>
Cc: Will Deacon <will@kernel.org>, Quentin Perret <qperret@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>, Joey Gouly <joey.gouly@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793921694; l=3950;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=OzLNUOC4vto8JqdWrzx35j81FrnSzjGjA2GXE09YggQ=;
 b=HUDjW/ZmysBcCBXniSKFPhnOhTavoITcJ1jjduOTg6SJw1V4bsVs6djzi+v4ELA5KYPjC9do7
 QBWylx+J0kMAZ4tYY1lgRngualFHsjiqY6MtYKLtE3nDpZwes4PjOHQ
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pKVM guest interface does not say what happens when a protected
guest issues MEM_SHARE and MEM_UNSHARE for the same page concurrently,
for example on two vCPUs.  The two calls are not ordered: a MEM_SHARE
that has not returned yet may take effect after a MEM_UNSHARE of the
same page has returned, and leave the page shared although the vCPU
that unshared it saw SUCCESS.

  vCPU A                         vCPU B
  ------                         ------
  MEM_SHARE(P) issued ...
                                 MEM_SHARE(P)    -> SUCCESS
                                 MEM_UNSHARE(P)  -> SUCCESS
                                 write private data to P
  ... MEM_SHARE(P) takes effect  -> SUCCESS: P is shared again

How long a share can stay pending is up to the host.  When the page is
not yet mapped in the guest's stage-2, pkvm_memshare_call() turns the
call into a data abort for the host (__pkvm_memshare_page_req()),
rewinds the guest's PC and exits; the share is performed from scratch
only when the host runs the vCPU again, with no record of the suspended
call and no lock held across it.  So the host can make vCPU A's share
complete after vCPU B's unshare, and read what B wrote to P.

Document that such calls are unordered, so that a guest knows it must
wait for all its shares of a region to return before treating the
region as private.

Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
We noticed this while studying pKVM's guest memory-sharing interface as
part of our research project, and are not sure whether documenting it is
the right answer.

A guest racing MEM_SHARE and MEM_UNSHARE of the same page on two vCPUs
is arguably asking for trouble, and Linux guests don't do it today.  But
nothing in the interface tells a guest when a page is private again,
and because a share of an unmapped page is suspended until the host
runs the vCPU again, the host controls how long the window stays open.
The alternative to this documentation change would be to record a
suspended MEM_SHARE (for example in the hyp vCPU) so that a later
MEM_UNSHARE of the same page cancels it, or to fail the unshare while a
share of that page is pending.  We'd be happy to work on either if you
prefer a code change.
---
 Documentation/virt/kvm/arm/hypercalls.rst | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/virt/kvm/arm/hypercalls.rst b/Documentation/virt/kvm/arm/hypercalls.rst
index 7400a89aa..ad7082da1 100644
--- a/Documentation/virt/kvm/arm/hypercalls.rst
+++ b/Documentation/virt/kvm/arm/hypercalls.rst
@@ -99,6 +99,16 @@ Revoke access permission from the KVM host to a memory region previously shared
 with ``ARM_SMCCC_KVM_FUNC_MEM_SHARE``. The size of the region is equal to the
 memory protection granule advertised by ``ARM_SMCCC_KVM_FUNC_HYP_MEMINFO``.
 
+Calls to ``ARM_SMCCC_KVM_FUNC_MEM_SHARE`` and ``ARM_SMCCC_KVM_FUNC_MEM_UNSHARE``
+for the same region that overlap in time, for example on different vCPUs, are
+not ordered with respect to each other: a share that has not yet returned may
+take effect after an unshare of the region has returned, leaving the region
+shared. A share of a region that is not yet mapped is restarted after the host
+has mapped it, so such a share can remain pending for as long as the host
+delays the vCPU. A guest must therefore not treat a region as private again
+until every ``ARM_SMCCC_KVM_FUNC_MEM_SHARE`` it issued for the region has
+returned.
+
 +---------------------+-------------------------------------------------------------+
 | Presence:           | Optional; pKVM protected guests only.                       |
 +---------------------+-------------------------------------------------------------+

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261105-mem-share-unshare-824c26c2cd0b

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

