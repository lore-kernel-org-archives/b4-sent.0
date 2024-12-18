From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:29:57 +0100
Subject: [PATCH 03/12] ansible: libvirt_user: Install additional pkgs for
 debian
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-3-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1055;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=XsFfSuOHOo7PdvXANRbQAmVGYrxSHmsJL8YTfwlMjVs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipCxwO69w7Vp2qva3tWlzugL0gj/d01iO9
 7r4RPbzRYB8x4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQsAAoJELqXzVK3
 lkFPMBIL+wRoqMDOlRiF1oJnbjYUP4sOFNjSuid59226mRUpQ9sjmFhYis0rOx9xJBMqFihHpYY
 64aYFaF/e9JgW9jeLXyrZOkS1Lq5y+2q1mJQDi6OrtOW+iZM8ijC6wvH6K0hiFTLPFj8dAcwWAL
 E2adFfYz/p1GuFRXcKYkt7I7Ov7S5IE9A3qd/ivLXYf+gVNIoKVZHOLdYDqwuQKmo+nAeWtxyTZ
 439YleEu5UQXroKTBVSBrW1/lHVTkuNtYKslHs4fD/82eBRJUulEDoCz2VGPTXH7AAT8Vrw7E6Z
 NwqXyhSn0GKahIwI5Ls0m/lFs8AuyXBZqP+6IRqkSmmlCrdB8hGz/i5EDf1hTPS701ihgUf1Byz
 NexREccKYxsB/d+GkCuopCFXEpIDutAZbsQmpwBhpKBpEkBtLXgGrKms3RHDiJgx9qW6kGh/lhY
 2/hRPkqq9FI5HP6U4gnTc1o6w4WMn3B4OHRLXhBrK/KBIlQepNHsP/PkG1jijYjHw9PUrUxMZp4
 F0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Install the following additional packages for debian
* libvirt-daemon-config-network: So we have networks/defaults.xml on the
  system and are sure we are able to generate the virtual network if
  needed.
* guestfs-tools: For when we use guestfs directory.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/libvirt_user/tasks/install-deps/debian/main.yml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/playbooks/roles/libvirt_user/tasks/install-deps/debian/main.yml b/playbooks/roles/libvirt_user/tasks/install-deps/debian/main.yml
index 792597f..98d0007 100644
--- a/playbooks/roles/libvirt_user/tasks/install-deps/debian/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/install-deps/debian/main.yml
@@ -13,10 +13,12 @@
     name:
       - libvirt-daemon
       - libvirt-daemon-system
+      - libvirt-daemon-config-network
       - libvirt-clients
       - qemu-kvm
       - qemu-system-x86
       - qemu-utils
+      - guestfs-tools
     state: present
   tags: install
 

-- 
2.44.2

