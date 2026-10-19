From: Manuel Huber <manuelh@nvidia.com>
Date: Mon, 19 Oct 2026 21:40:28 +0000
Subject: [PATCH RFC 4/4] selftests/ipe: test the IPE policy keyring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-b4-ipe-keyring-rfc-v1-4-156f0b93e843@nvidia.com>
References: <20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com>
In-Reply-To: <20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com>
To: Fan Wu <wufan@kernel.org>, David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: Christian Brauner <brauner@kernel.org>, 
 Andrew Halaney <andrew@amutable.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Randy Dunlap <rdunlap@infradead.org>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 linux-security-module@vger.kernel.org, keyrings@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-doc@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Manuel Huber <manuelh@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792446042; l=14731;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=euxFDjmdpErQTrvz4GFkvmeoAJdo58XBC2o7BXea+go=;
 b=oU6JZekoZVofgKaEYBokR0VU8DubhQaUrCgNE48/C9gNVUT+2VgMwqLcNxOiFmPcoCT1sBb9I
 sD54tMyJzWqAg3jtC0TNsFINBfmFhrhwUmdaNoIInoHrospjnmyKfOK
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an IPE kselftest that validates policy keyring operations for
both ipe.keyring_unsealed values 0 and 1.

For the default ipe.keyring_unsealed=0, verify that a) the special key
ID resolves, b) certificate enrollment is rejected, and c) the keyring
is not used for policy verification.
For ipe.keyring_unsealed=1, verify that we can a) provision multiple
certificates, b) restrict the keyring, then reject unenrolled and
corrupted signatures, c) authenticate policy loads and updates with
different enrolled certificates.

Since IPE is built in, keyring restriction is irreversible, which is
why we can only exercise the initially sealed and unsealed scenarios
via separate boots. To get full coverage, CI thus needs to spin up
separate environments with respective parameter values.

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
 MAINTAINERS                                     |   1 +
 tools/testing/selftests/Makefile                |   1 +
 tools/testing/selftests/ipe/Makefile            |   5 +
 tools/testing/selftests/ipe/config              |   7 +
 tools/testing/selftests/ipe/test-ipe-keyring.sh | 357 ++++++++++++++++++++++++
 5 files changed, 371 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 65e8a4b5c90b..818f9968b315 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12967,6 +12967,7 @@ F:	Documentation/admin-guide/LSM/ipe.rst
 F:	Documentation/security/ipe.rst
 F:	scripts/ipe/
 F:	security/ipe/
+F:	tools/testing/selftests/ipe/
 
 INTEL 810/815 FRAMEBUFFER DRIVER
 M:	Antonino Daplas <adaplas@gmail.com>
diff --git a/tools/testing/selftests/Makefile b/tools/testing/selftests/Makefile
index 273853937c25..16ba45a12c5b 100644
--- a/tools/testing/selftests/Makefile
+++ b/tools/testing/selftests/Makefile
@@ -59,6 +59,7 @@ TARGETS += hid
 TARGETS += intel_pstate
 TARGETS += iommu
 TARGETS += ipc
+TARGETS += ipe
 TARGETS += ir
 TARGETS += kcmp
 TARGETS += kexec
diff --git a/tools/testing/selftests/ipe/Makefile b/tools/testing/selftests/ipe/Makefile
new file mode 100644
index 000000000000..f281e68329c1
--- /dev/null
+++ b/tools/testing/selftests/ipe/Makefile
@@ -0,0 +1,5 @@
+# SPDX-License-Identifier: GPL-2.0
+
+TEST_PROGS := test-ipe-keyring.sh
+
+include ../lib.mk
diff --git a/tools/testing/selftests/ipe/config b/tools/testing/selftests/ipe/config
new file mode 100644
index 000000000000..498c224d2c18
--- /dev/null
+++ b/tools/testing/selftests/ipe/config
@@ -0,0 +1,7 @@
+CONFIG_AUDIT=y
+CONFIG_AUDITSYSCALL=y
+CONFIG_KEYS=y
+CONFIG_PROC_FS=y
+CONFIG_SECURITY=y
+CONFIG_SECURITYFS=y
+CONFIG_SECURITY_IPE=y
diff --git a/tools/testing/selftests/ipe/test-ipe-keyring.sh b/tools/testing/selftests/ipe/test-ipe-keyring.sh
new file mode 100755
index 000000000000..557ccc825fe2
--- /dev/null
+++ b/tools/testing/selftests/ipe/test-ipe-keyring.sh
@@ -0,0 +1,357 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Run from the kernel source tree with:
+#   make -C tools/testing/selftests TARGETS=ipe run_tests
+#
+# Full coverage requires one boot with the default command line and another
+# with ipe.keyring_unsealed=1. The test selects the matching mode automatically.
+# The provisioning mode irreversibly restricts and locks the .ipe keyring, so
+# run it once per boot on a disposable test system.
+#
+# Requirements: root with CAP_MAC_ADMIN, keyctl, and openssl.
+
+DIR="$(dirname "$(readlink -f "$0")")"
+# shellcheck source=../kselftest/ktap_helpers.sh
+source "${DIR}/../kselftest/ktap_helpers.sh"
+
+KEY_SPEC_IPE_KEYRING=-12
+IPE_KEYRING_PERM_LOCKED=0x08030000
+IPE_KEYRING_PERM_INITIAL=0x082f0000
+SECURITYFS=/sys/kernel/security
+IPEFS="$SECURITYFS/ipe"
+WORK_DIR=
+MOUNTED_SECURITYFS=0
+POLICY_NAME="ipe_keyring_selftest_$$"
+WRONG_POLICY_NAME="${POLICY_NAME}_wrong"
+POLICY_LOADED=0
+WRONG_POLICY_LOADED=0
+
+skip()
+{
+	ktap_skip_all "$*"
+	exit "$KSFT_SKIP"
+}
+
+fail()
+{
+	ktap_test_fail "$*"
+	ktap_finished
+}
+
+# shellcheck disable=SC2329 # invoked indirectly via trap
+cleanup()
+{
+	if [ "$WRONG_POLICY_LOADED" -eq 1 ] &&
+	   [ -w "$IPEFS/policies/$WRONG_POLICY_NAME/delete" ]; then
+		echo 1 > "$IPEFS/policies/$WRONG_POLICY_NAME/delete" 2>/dev/null || true
+	fi
+
+	if [ "$POLICY_LOADED" -eq 1 ] &&
+	   [ -w "$IPEFS/policies/$POLICY_NAME/delete" ]; then
+		echo 1 > "$IPEFS/policies/$POLICY_NAME/delete" 2>/dev/null || true
+	fi
+
+	if [ "$MOUNTED_SECURITYFS" -eq 1 ]; then
+		umount "$SECURITYFS" 2>/dev/null || true
+	fi
+
+	if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
+		rm -rf -- "$WORK_DIR"
+	fi
+}
+
+trap cleanup EXIT
+
+require_command()
+{
+	command -v "$1" >/dev/null 2>&1 || skip "missing command: $1"
+}
+
+generate_keypair()
+{
+	local name=$1
+
+	if ! openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes -days 1 \
+		-subj "/CN=IPE keyring selftest $name/" \
+		-addext "basicConstraints=critical,CA:FALSE" \
+		-addext "keyUsage=critical,digitalSignature" \
+		-keyout "$WORK_DIR/$name-key.pem" \
+		-out "$WORK_DIR/$name-cert.pem" >/dev/null \
+		2> "$WORK_DIR/$name-openssl.log"; then
+		cat "$WORK_DIR/$name-openssl.log" >&2
+		fail "generate the $name signing key"
+	fi
+
+	if ! openssl x509 -in "$WORK_DIR/$name-cert.pem" -outform DER \
+		-out "$WORK_DIR/$name-cert.der" >/dev/null \
+		2> "$WORK_DIR/$name-openssl.log"; then
+		cat "$WORK_DIR/$name-openssl.log" >&2
+		fail "convert the $name certificate to DER"
+	fi
+}
+
+make_policy()
+{
+	local name=$1
+	local version=$2
+	local output=$3
+
+	printf 'policy_name=%s policy_version=%s\nDEFAULT action=ALLOW\n' \
+		"$name" "$version" > "$output"
+}
+
+sign_policy()
+{
+	local policy=$1
+	local signer=$2
+	local output=$3
+
+	if ! openssl smime -sign -in "$policy" \
+		-signer "$WORK_DIR/$signer-cert.pem" \
+		-inkey "$WORK_DIR/$signer-key.pem" \
+		-noattr -nodetach -nosmimecap -outform DER \
+		-out "$output" >/dev/null \
+		2> "$WORK_DIR/$signer-openssl.log"; then
+		cat "$WORK_DIR/$signer-openssl.log" >&2
+		fail "sign policy with the $signer key"
+	fi
+}
+
+corrupt_signed_policy()
+{
+	local input=$1
+	local output=$2
+	local signed_size
+	local corrupt_offset
+
+	cp -- "$input" "$output" || fail "copy the signed policy"
+	signed_size=$(wc -c < "$output") || fail "measure the signed policy"
+	[ "$signed_size" -gt 16 ] || fail "signed policy is unexpectedly short"
+	corrupt_offset=$((signed_size - 16))
+	printf '\377\377\377\377' | dd of="$output" bs=1 \
+		seek="$corrupt_offset" conv=notrunc >/dev/null 2>&1 ||
+		fail "corrupt the signed policy"
+}
+
+keyring_key_count()
+{
+	local output
+
+	output=$(keyctl list "$KEY_SPEC_IPE_KEYRING" 2>/dev/null) || return 1
+	awk 'NR == 1 {
+		if ($0 ~ /empty/)
+			print 0
+		else if ($1 ~ /^[0-9]+$/)
+			print $1
+		else
+			exit 1
+	}' <<< "$output"
+}
+
+check_locked_mutations()
+{
+	local key_serial=$1
+	local keyring_serial=$2
+
+	if keyctl unlink "$key_serial" "$keyring_serial" >/dev/null 2>&1; then
+		fail "locked keyring allowed its certificate to be unlinked"
+	fi
+	if keyctl clear "$keyring_serial" >/dev/null 2>&1; then
+		fail "locked keyring allowed its contents to be cleared"
+	fi
+	if keyctl revoke "$keyring_serial" >/dev/null 2>&1; then
+		fail "locked keyring allowed itself to be revoked"
+	fi
+	if keyctl invalidate "$keyring_serial" >/dev/null 2>&1; then
+		fail "locked keyring allowed itself to be invalidated"
+	fi
+	if keyctl timeout "$keyring_serial" 1 >/dev/null 2>&1; then
+		fail "locked keyring allowed a timeout to be set"
+	fi
+	if keyctl setperm "$keyring_serial" \
+		"$IPE_KEYRING_PERM_INITIAL" >/dev/null 2>&1; then
+		fail "locked keyring allowed its permissions to be restored"
+	fi
+}
+
+test_sealed_keyring()
+{
+	local key_count
+
+	ktap_set_plan 4
+	ktap_test_pass "KEY_SPEC_IPE_KEYRING resolves to the .ipe keyring"
+
+	key_count=$(keyring_key_count) || fail "read the sealed keyring"
+	[ "$key_count" = 0 ] || fail "sealed-default keyring is not empty"
+	ktap_test_pass "the default keyring is empty"
+
+	generate_keypair trusted
+	if keyctl padd asymmetric "ipe-selftest-$$" \
+		"$KEY_SPEC_IPE_KEYRING" < "$WORK_DIR/trusted-cert.der" \
+		>/dev/null 2>&1; then
+		fail "sealed-default keyring accepted a certificate"
+	fi
+	ktap_test_pass "the default keyring rejects new certificates"
+
+	make_policy "$POLICY_NAME" 0.0.1 "$WORK_DIR/policy-v1"
+	sign_policy "$WORK_DIR/policy-v1" trusted "$WORK_DIR/policy-v1.p7b"
+	if cat "$WORK_DIR/policy-v1.p7b" > "$IPEFS/new_policy" 2>/dev/null; then
+		POLICY_LOADED=1
+		fail "empty .ipe keyring authenticated a policy"
+	fi
+	ktap_test_pass "the empty keyring is not used for policy verification"
+}
+
+test_unsealed_keyring()
+{
+	local key_count
+	local key_serial
+
+	ktap_set_plan 16
+	ktap_test_pass "KEY_SPEC_IPE_KEYRING resolves to the .ipe keyring"
+
+	key_count=$(keyring_key_count) || fail "read the unsealed keyring"
+	[ "$key_count" = 0 ] || fail "unsealed keyring is not empty"
+	ktap_test_pass "the unsealed keyring starts empty"
+
+	generate_keypair trusted
+	generate_keypair trusted-alt
+	generate_keypair untrusted
+	key_serial=$(keyctl padd asymmetric "ipe-selftest-$$" \
+		"$KEY_SPEC_IPE_KEYRING" < "$WORK_DIR/trusted-cert.der" \
+		2>/dev/null) || fail "add a certificate to the unsealed keyring"
+	keyctl padd asymmetric "ipe-selftest-alt-$$" \
+		"$KEY_SPEC_IPE_KEYRING" < "$WORK_DIR/trusted-alt-cert.der" \
+		>/dev/null 2>&1 || fail "add a second certificate to the keyring"
+	key_count=$(keyring_key_count) || fail "count the provisioned certificates"
+	[ "$key_count" = 2 ] || fail "keyring does not contain two certificates"
+	ktap_test_pass "multiple certificates can be provisioned"
+
+	make_policy "$POLICY_NAME" 0.0.1 "$WORK_DIR/policy-v1"
+	sign_policy "$WORK_DIR/policy-v1" trusted "$WORK_DIR/policy-v1.p7b"
+	if cat "$WORK_DIR/policy-v1.p7b" > "$IPEFS/new_policy" 2>/dev/null; then
+		POLICY_LOADED=1
+		fail "unrestricted .ipe keyring authenticated a policy"
+	fi
+	ktap_test_pass "an unrestricted keyring is not used for verification"
+
+	keyctl restrict_keyring "$KEY_SPEC_IPE_KEYRING" >/dev/null 2>&1 ||
+		fail "restrict the provisioned keyring"
+	ktap_test_pass "the provisioned keyring can be restricted"
+
+	if printf x | keyctl padd user "ipe-selftest-probe-$$" \
+		"$KEY_SPEC_IPE_KEYRING" >/dev/null 2>&1; then
+		fail "restricted keyring accepted another key"
+	fi
+	ktap_test_pass "the restricted keyring rejects additional keys"
+
+	make_policy "$WRONG_POLICY_NAME" 0.0.1 "$WORK_DIR/policy-wrong"
+	sign_policy "$WORK_DIR/policy-wrong" untrusted \
+		"$WORK_DIR/policy-wrong.p7b"
+	if cat "$WORK_DIR/policy-wrong.p7b" > "$IPEFS/new_policy" 2>/dev/null; then
+		WRONG_POLICY_LOADED=1
+		fail "an unenrolled certificate authenticated a policy"
+	fi
+	ktap_test_pass "an unenrolled certificate is rejected"
+
+	corrupt_signed_policy "$WORK_DIR/policy-v1.p7b" \
+		"$WORK_DIR/policy-v1-corrupt.p7b"
+	if cat "$WORK_DIR/policy-v1-corrupt.p7b" \
+		> "$IPEFS/new_policy" 2>/dev/null; then
+		POLICY_LOADED=1
+		fail "a corrupted signed policy was authenticated"
+	fi
+	ktap_test_pass "a corrupted signed policy is rejected"
+
+	cat "$WORK_DIR/policy-v1.p7b" > "$IPEFS/new_policy" 2>/dev/null ||
+		fail "load a policy signed by the enrolled certificate"
+	POLICY_LOADED=1
+	ktap_test_pass "the restricted keyring authenticates a policy"
+
+	[ "$(cat "$IPEFS/policies/$POLICY_NAME/name")" = "$POLICY_NAME" ] &&
+		[ "$(cat "$IPEFS/policies/$POLICY_NAME/version")" = 0.0.1 ] ||
+		fail "loaded policy metadata does not match"
+	ktap_test_pass "the authenticated policy metadata matches"
+
+	keyctl setperm "$KEY_SPEC_IPE_KEYRING" \
+		"$IPE_KEYRING_PERM_LOCKED" >/dev/null 2>&1 ||
+		fail "drop mutation permissions from the keyring"
+	ktap_test_pass "mutation permissions can be dropped"
+
+	if keyctl id "$KEY_SPEC_IPE_KEYRING" >/dev/null 2>&1; then
+		fail "the special key ID granted possession rights"
+	fi
+	ktap_test_pass "the special key ID grants no possession rights"
+
+	check_locked_mutations "$key_serial" "$keyring_serial"
+	ktap_test_pass "locked-keyring mutation attempts are rejected"
+
+	make_policy "$POLICY_NAME" 0.0.2 "$WORK_DIR/policy-v2"
+	sign_policy "$WORK_DIR/policy-v2" trusted-alt "$WORK_DIR/policy-v2.p7b"
+	cat "$WORK_DIR/policy-v2.p7b" \
+		> "$IPEFS/policies/$POLICY_NAME/update" 2>/dev/null ||
+		fail "update a policy signed by the second enrolled certificate"
+	ktap_test_pass "the second enrolled certificate authenticates policy updates"
+
+	[ "$(cat "$IPEFS/policies/$POLICY_NAME/version")" = 0.0.2 ] ||
+		fail "policy version was not updated"
+	ktap_test_pass "the authenticated policy update was installed"
+
+	echo 1 > "$IPEFS/policies/$POLICY_NAME/delete" 2>/dev/null ||
+		fail "delete the inactive test policy"
+	POLICY_LOADED=0
+	ktap_test_pass "the inactive test policy can be removed"
+}
+
+ktap_print_header
+
+for command in awk cat cp dd grep id keyctl mktemp mount openssl rm umount wc; do
+	require_command "$command"
+done
+
+[ "$(id -u)" -eq 0 ] || skip "must be run as root"
+
+cap_eff=$(awk '/^CapEff:/ { print $2 }' /proc/self/status)
+[ -n "$cap_eff" ] || skip "cannot read effective capabilities"
+(( (16#$cap_eff & (1 << 33)) != 0 )) || skip "CAP_MAC_ADMIN is required"
+
+WORK_DIR=$(mktemp -d -t ipe-keyring-test.XXXXXX) ||
+	skip "cannot create a temporary directory"
+
+if ! grep -qs " $SECURITYFS securityfs " /proc/mounts; then
+	mount -t securityfs none "$SECURITYFS" >/dev/null 2>&1 ||
+		skip "cannot mount securityfs"
+	MOUNTED_SECURITYFS=1
+fi
+
+[ -w "$IPEFS/new_policy" ] || skip "IPE is not enabled"
+[ -r /sys/module/ipe/parameters/keyring_unsealed ] ||
+	skip "IPE policy keyring is not available"
+
+keyring_serial=$(keyctl id "$KEY_SPEC_IPE_KEYRING" 2>/dev/null) ||
+	skip "KEY_SPEC_IPE_KEYRING does not resolve"
+keyring_description=$(keyctl describe "$keyring_serial" 2>/dev/null) ||
+	skip "cannot describe the IPE keyring"
+case "$keyring_description" in
+	*"keyring: .ipe") ;;
+	*) skip "KEY_SPEC_IPE_KEYRING resolved to an unexpected key" ;;
+esac
+
+keyring_unsealed=$(cat /sys/module/ipe/parameters/keyring_unsealed)
+case "$keyring_unsealed" in
+	Y)
+		[ "$(keyring_key_count)" = 0 ] ||
+			skip "the IPE keyring has already been provisioned"
+		test_unsealed_keyring
+		;;
+	N)
+		test_sealed_keyring
+		;;
+	*)
+		ktap_exit_fail_msg \
+			"unexpected ipe.keyring_unsealed value: $keyring_unsealed"
+		;;
+esac
+
+ktap_finished

-- 
2.53.0

