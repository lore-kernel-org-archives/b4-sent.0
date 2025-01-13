From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:01 +0100
Subject: [PATCH RESEND 03/12] ansible: libvirt_user: Install additional
 pkgs for debian
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-3-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1055;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=XsFfSuOHOo7PdvXANRbQAmVGYrxSHmsJL8YTfwlMjVs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qMfOY/45CzTw2XtBV8IN10ADkLpsyKsG
 +hM0SNMMhBXmokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6jAAoJELqXzVK3
 lkFPtq4L/iD3WV9gCbdbOUXcOCMM/ILjBZ2XG7fPsKH7JqwfqnJdh0Wf6a9QoHA9oMCnCJYu2YE
 9OZFqdJdmotCLm/b5gSgiaq7PEFEF1gKvB9tof40JhhxV4spWvftZ07OYJ2FW0il5GpXm9maimN
 izn+yIWxuykVsFFZrBHdpPWisuiuAEBX7bacgeKKvHK2eJcujykUWe/eNUZqzWjV55VQasYVtUO
 h/PBv5evTyIA3zebxzTIo85bGKeA4aofinegbaqpQvwxDK0Q6F5Ylh1EkyYMwZUFyFy5MTfRXXc
 C9eyUDjeqZVzLjidPvLc3M35gzm+1/eakGAq0A7UgdSTJzrrEx0QfIzmhWLLb7WpLXeFubKqQtU
 ijdT86gjy1U+gdVwMtId4vWbHf9NrdkoPIirD2O/k4dIssLTga2/HS4K6FEQfPzs8uIF9dMIP9f
 i3i2ZrLuz2t0QdmRmM9Y+IEZ4mBD3LWIRlry9JM0khYQP0ZuKo7qTbrN1twS++5zkROJz2TgQP6
 hY=
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

