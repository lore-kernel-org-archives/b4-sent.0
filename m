From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 27 Nov 2023 18:40:09 -0600
Subject: [PATCH] powerpc/rtas_pci: rename and properly expose config access
 APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231127-rtas-pci-rw-config-v1-1-385d29ace3df@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAOk2ZWUC/x3MMQqAMAxA0atIZgNtRAWvIg6lppqllVRUKN7d4
 viG/wtkVuEMU1NA+ZIsKVbYtgG/u7gxyloNZKizlkbU02U8vKDe6FMMsiEZ1w/WBFq7Hmp4KAd
 5/um8vO8Hvq+MEGQAAAA=
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Palmer Dabbelt <palmer@rivosinc.com>, Arnd Bergmann <arnd@arndb.de>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Kees Cook <keescook@chromium.org>
Cc: lkft-triage@lists.linaro.org, Benjamin Gray <bgray@linux.ibm.com>, 
 Arnd Bergmann <arnd@arndb.de>, Nathan Chancellor <nathan@kernel.org>, 
 Anders Roxell <anders.roxell@linaro.org>, 
 Dan Carpenter <dan.carpenter@linaro.org>, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, clang-built-linux <llvm@lists.linux.dev>, 
 regressions@lists.linux.dev, 
 Linux Kernel Functional Testing <lkft@linaro.org>, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701132037; l=7740;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=jedyw4vu/T4uAMv9jtKkjATg+3BmdKuMIcKlpdHEM+E=;
 b=z9fpMpvCrtxWqHhOrHpwe2l+zQKGqgpGR+iOa/99ZkVdBd411YMCgseolqFW5xzSQIscfzo9M
 BCg5/0hmGOTDxE4jTzvqHC1Kj/iqOCcVRhFNLd0PHr7StGVwpdMk31l
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rtas_read_config() and rtas_write_config() functions in
kernel/rtas_pci.c have external linkage and two users in arch/powerpc:
the rtas_pci code itself and the pseries platform's "enhanced error
handling" (EEH) support code.

The prototypes for these functions in asm/ppc-pci.h have until now
been guarded by CONFIG_EEH since the only external caller is the
pseries EEH code. However, this presumably has always generated
warnings when built with !CONFIG_EEH and -Wmissing-prototypes:

  arch/powerpc/kernel/rtas_pci.c:46:5: error: no previous prototype for
  function 'rtas_read_config' [-Werror,-Wmissing-prototypes]
     46 | int rtas_read_config(struct pci_dn *pdn, int where,
                               int size, u32 *val)

  arch/powerpc/kernel/rtas_pci.c:98:5: error: no previous prototype for
  function 'rtas_write_config' [-Werror,-Wmissing-prototypes]
     98 | int rtas_write_config(struct pci_dn *pdn, int where,
                                int size, u32 val)

The introduction of commit c6345dfa6e3e ("Makefile.extrawarn: turn on
missing-prototypes globally") forces the issue.

The efika and chrp platform code have (static) functions with the same
names but different signatures. We may as well eliminate the potential
for conflicts and confusion by renaming the globally visible versions
as their prototypes get moved out of the CONFIG_EEH-guarded region;
their current names are too generic anyway. Since they operate on
objects of the type 'struct pci_dn *', give them the slightly more
verbose prefix "rtas_pci_dn_" and fix up all the call sites.

Fixes: c6345dfa6e3e ("Makefile.extrawarn: turn on missing-prototypes globally")
Reported-by: Linux Kernel Functional Testing <lkft@linaro.org>
Closes: https://lore.kernel.org/linuxppc-dev/CA+G9fYt0LLXtjSz+Hkf3Fhm-kf0ZQanrhUS+zVZGa3O+Wt2+vg@mail.gmail.com/
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/ppc-pci.h           |  5 +++--
 arch/powerpc/kernel/rtas_pci.c               |  8 ++++----
 arch/powerpc/platforms/pseries/eeh_pseries.c | 18 +++++++++---------
 3 files changed, 16 insertions(+), 15 deletions(-)

diff --git a/arch/powerpc/include/asm/ppc-pci.h b/arch/powerpc/include/asm/ppc-pci.h
index d9fcff575027..ce2b1b5eebdd 100644
--- a/arch/powerpc/include/asm/ppc-pci.h
+++ b/arch/powerpc/include/asm/ppc-pci.h
@@ -35,6 +35,9 @@ extern void init_pci_config_tokens (void);
 extern unsigned long get_phb_buid (struct device_node *);
 extern int rtas_setup_phb(struct pci_controller *phb);
 
+int rtas_pci_dn_read_config(struct pci_dn *pdn, int where, int size, u32 *val);
+int rtas_pci_dn_write_config(struct pci_dn *pdn, int where, int size, u32 val);
+
 #ifdef CONFIG_EEH
 
 void eeh_addr_cache_insert_dev(struct pci_dev *dev);
@@ -44,8 +47,6 @@ void eeh_slot_error_detail(struct eeh_pe *pe, int severity);
 int eeh_pci_enable(struct eeh_pe *pe, int function);
 int eeh_pe_reset_full(struct eeh_pe *pe, bool include_passed);
 void eeh_save_bars(struct eeh_dev *edev);
-int rtas_write_config(struct pci_dn *, int where, int size, u32 val);
-int rtas_read_config(struct pci_dn *, int where, int size, u32 *val);
 void eeh_pe_state_mark(struct eeh_pe *pe, int state);
 void eeh_pe_mark_isolated(struct eeh_pe *pe);
 void eeh_pe_state_clear(struct eeh_pe *pe, int state, bool include_passed);
diff --git a/arch/powerpc/kernel/rtas_pci.c b/arch/powerpc/kernel/rtas_pci.c
index e1fdc7473b72..fccf96e897f6 100644
--- a/arch/powerpc/kernel/rtas_pci.c
+++ b/arch/powerpc/kernel/rtas_pci.c
@@ -43,7 +43,7 @@ static inline int config_access_valid(struct pci_dn *dn, int where)
 	return 0;
 }
 
-int rtas_read_config(struct pci_dn *pdn, int where, int size, u32 *val)
+int rtas_pci_dn_read_config(struct pci_dn *pdn, int where, int size, u32 *val)
 {
 	int returnval = -1;
 	unsigned long buid, addr;
@@ -87,7 +87,7 @@ static int rtas_pci_read_config(struct pci_bus *bus,
 	pdn = pci_get_pdn_by_devfn(bus, devfn);
 
 	/* Validity of pdn is checked in here */
-	ret = rtas_read_config(pdn, where, size, val);
+	ret = rtas_pci_dn_read_config(pdn, where, size, val);
 	if (*val == EEH_IO_ERROR_VALUE(size) &&
 	    eeh_dev_check_failure(pdn_to_eeh_dev(pdn)))
 		return PCIBIOS_DEVICE_NOT_FOUND;
@@ -95,7 +95,7 @@ static int rtas_pci_read_config(struct pci_bus *bus,
 	return ret;
 }
 
-int rtas_write_config(struct pci_dn *pdn, int where, int size, u32 val)
+int rtas_pci_dn_write_config(struct pci_dn *pdn, int where, int size, u32 val)
 {
 	unsigned long buid, addr;
 	int ret;
@@ -134,7 +134,7 @@ static int rtas_pci_write_config(struct pci_bus *bus,
 	pdn = pci_get_pdn_by_devfn(bus, devfn);
 
 	/* Validity of pdn is checked in here. */
-	return rtas_write_config(pdn, where, size, val);
+	return rtas_pci_dn_write_config(pdn, where, size, val);
 }
 
 static struct pci_ops rtas_pci_ops = {
diff --git a/arch/powerpc/platforms/pseries/eeh_pseries.c b/arch/powerpc/platforms/pseries/eeh_pseries.c
index def184da51cf..b1ae0c0d1187 100644
--- a/arch/powerpc/platforms/pseries/eeh_pseries.c
+++ b/arch/powerpc/platforms/pseries/eeh_pseries.c
@@ -252,7 +252,7 @@ static int pseries_eeh_cap_start(struct pci_dn *pdn)
 	if (!pdn)
 		return 0;
 
-	rtas_read_config(pdn, PCI_STATUS, 2, &status);
+	rtas_pci_dn_read_config(pdn, PCI_STATUS, 2, &status);
 	if (!(status & PCI_STATUS_CAP_LIST))
 		return 0;
 
@@ -270,11 +270,11 @@ static int pseries_eeh_find_cap(struct pci_dn *pdn, int cap)
 		return 0;
 
         while (cnt--) {
-		rtas_read_config(pdn, pos, 1, &pos);
+		rtas_pci_dn_read_config(pdn, pos, 1, &pos);
 		if (pos < 0x40)
 			break;
 		pos &= ~3;
-		rtas_read_config(pdn, pos + PCI_CAP_LIST_ID, 1, &id);
+		rtas_pci_dn_read_config(pdn, pos + PCI_CAP_LIST_ID, 1, &id);
 		if (id == 0xff)
 			break;
 		if (id == cap)
@@ -294,7 +294,7 @@ static int pseries_eeh_find_ecap(struct pci_dn *pdn, int cap)
 
 	if (!edev || !edev->pcie_cap)
 		return 0;
-	if (rtas_read_config(pdn, pos, 4, &header) != PCIBIOS_SUCCESSFUL)
+	if (rtas_pci_dn_read_config(pdn, pos, 4, &header) != PCIBIOS_SUCCESSFUL)
 		return 0;
 	else if (!header)
 		return 0;
@@ -307,7 +307,7 @@ static int pseries_eeh_find_ecap(struct pci_dn *pdn, int cap)
 		if (pos < 256)
 			break;
 
-		if (rtas_read_config(pdn, pos, 4, &header) != PCIBIOS_SUCCESSFUL)
+		if (rtas_pci_dn_read_config(pdn, pos, 4, &header) != PCIBIOS_SUCCESSFUL)
 			break;
 	}
 
@@ -412,8 +412,8 @@ static void pseries_eeh_init_edev(struct pci_dn *pdn)
 	if ((pdn->class_code >> 8) == PCI_CLASS_BRIDGE_PCI) {
 		edev->mode |= EEH_DEV_BRIDGE;
 		if (edev->pcie_cap) {
-			rtas_read_config(pdn, edev->pcie_cap + PCI_EXP_FLAGS,
-					 2, &pcie_flags);
+			rtas_pci_dn_read_config(pdn, edev->pcie_cap + PCI_EXP_FLAGS,
+						2, &pcie_flags);
 			pcie_flags = (pcie_flags & PCI_EXP_FLAGS_TYPE) >> 4;
 			if (pcie_flags == PCI_EXP_TYPE_ROOT_PORT)
 				edev->mode |= EEH_DEV_ROOT_PORT;
@@ -676,7 +676,7 @@ static int pseries_eeh_read_config(struct eeh_dev *edev, int where, int size, u3
 {
 	struct pci_dn *pdn = eeh_dev_to_pdn(edev);
 
-	return rtas_read_config(pdn, where, size, val);
+	return rtas_pci_dn_read_config(pdn, where, size, val);
 }
 
 /**
@@ -692,7 +692,7 @@ static int pseries_eeh_write_config(struct eeh_dev *edev, int where, int size, u
 {
 	struct pci_dn *pdn = eeh_dev_to_pdn(edev);
 
-	return rtas_write_config(pdn, where, size, val);
+	return rtas_pci_dn_write_config(pdn, where, size, val);
 }
 
 #ifdef CONFIG_PCI_IOV

---
base-commit: 0d555b57ee660d8a871781c0eebf006e855e918d
change-id: 20231127-rtas-pci-rw-config-20a5610f2d35

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

