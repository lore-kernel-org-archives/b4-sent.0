From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH 0/2] Fix bugs in HugeTLB allocation when
 mem_cgroup_charge_hugetlb() fails
Date: Wed, 02 Sep 2026 01:22:55 -0700
Message-Id: <20260902-hugetlb-alloc-folio-memcg-charge-error-handling-v1-0-e3e8942c141b@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN/cl2oC/x2N0QrCMAxFf2Xk2UBXaVF/RXyYXdoFslbSKcLYv
 xt8PHDuuTt0UqYOt2EHpQ93btVgPA2QlqkWQp6NwTsf3dWNuLwLbfLESaQlzE244UprKmi+mk+
 qTdG2s3AtGC7RUzx7CjmAVV9Kmb//x/vjOH6S4QqagQAAAA==
X-Change-ID: 20260901-hugetlb-alloc-folio-memcg-charge-error-handling-5862e632e5f5
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, jthoughton@google.com, 
 fvdl@google.com, rientjes@google.com, vannapurve@google.com, 
 Suren Baghdasaryan <surenb@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Wupeng Ma <mawupeng1@huawei.com>, Yanteng Si <si.yanteng@linux.dev>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788337379; l=5404;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=9s2vpaiXD6s4W26CbucrW3C0rPFnD/K26BzyCEp2oKI=;
 b=2WFDdksKyvJUDYhmN6mhW3mHuuBJDYSVhnCKZRLzvGT3p8ao0/FZrWrDMPZmoSB6VWfrJvYfO
 ZqEvKDgvDdCDsVLiWbMo1LGxxx+0rHv9PX0GIJuxC/JRx33OyDcKnLS
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In hugetlb_alloc_folio(), when mem_cgroup_charge_hugetlb() fails, there are
2 issues:

1. free_huge_folio() expects a non-refcounted folio and will
   VM_BUG_ON_FOLIO().

2. -ENOMEM is returned, causing an infinite loop retrying the fault.

This patch series is a subset of patches in [1].

Note: [1] was applied on an earlier version of HugeTLB allocation. In that
earlier version, VMA reservations were not undone on
mem_cgroup_charge_hugetlb() failure.

5737df3826dee: ("mm: hugetlb: refactor out hugetlb_alloc_folio()") fixed
that, since returning an error from hugetlb_alloc_folio() causes
alloc_hugetlb_folio() to execute vma_end_reservation().

In [2], an earlier revision of [1], "mm: hugetlb: Drop refcount before
freeing on memcg charge failure" was named "mm: hugetlb: Fix folio refcount
mismatch on memcg charge failure".

[1] https://lore.kernel.org/all/20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com/
[2] https://lore.kernel.org/all/20260708-hugetlb-alloc-failure-fixes-v2-0-c7f27cbb462b@google.com/

Here's a reproducer to trigger mem_cgroup_charge_hugetlb() failure:

static void write_file_val(const char *path, const char *val)
{
	int fd = open(path, O_WRONLY);

	if (fd < 0) {
		fprintf(stderr, "Failed to open %s: %s\n", path, strerror(errno));
		exit(1);
	}
	if (write(fd, val, strlen(val)) < 0) {
		fprintf(stderr, "Failed to write %s to %s: %s\n", val, path, strerror(errno));
		close(fd);
		exit(1);
	}
	close(fd);
}

static int is_hugetlb_accounting_enabled(void)
{
	char spec[256], file[256], type[256], opts[512];
	char line[1024];
	int enabled = 0;
	FILE *fp;

	fp = fopen("/proc/mounts", "r");
	if (!fp) {
		perror("fopen /proc/mounts");
		return -1;
	}

	while (fgets(line, sizeof(line), fp)) {
		if (sscanf(line, "%255s %255s %255s %511s", spec, file, type, opts) == 4) {
			if (strcmp(file, CGROUP_PATH) == 0 && strcmp(type, "cgroup2") == 0) {
				if (strstr(opts, "memory_hugetlb_accounting") != NULL)
					enabled = 1;
				break;
			}
		}
	}
	fclose(fp);
	return enabled;
}

static int enable_hugetlb_accounting(void)
{
	int ret;

	printf("Attempting to remount cgroup2 with memory_hugetlb_accounting...\n");
	ret = system("mount -o remount,memory_hugetlb_accounting " CGROUP_PATH);
	if (ret != 0) {
		fprintf(stderr, "Failed to remount: system() returned %d\n", ret);
		return -1;
	}
	return 0;
}

int main(int argc, char **argv)
{
	struct stat st;
	size_t size;
	void *addr;
	pid_t pid;
	int enabled;
	int status;
	int fd;

	if (stat(CGROUP_PATH, &st) != 0 || !S_ISDIR(st.st_mode)) {
		fprintf(stderr, "cgroup v2 not mounted at %s\n", CGROUP_PATH);
		return 1;
	}

	enabled = is_hugetlb_accounting_enabled();
	if (enabled < 0)
		return 1;

	if (!enabled) {
		if (enable_hugetlb_accounting() != 0) {
			fprintf(stderr, "Could not enable memory_hugetlb_accounting\n");
			return 1;
		}
		/* Re-check */
		enabled = is_hugetlb_accounting_enabled();
		if (enabled <= 0) {
			fprintf(stderr, "Failed to enable memory_hugetlb_accounting (re-check failed)\n");
			return 1;
		}
		printf("Successfully enabled memory_hugetlb_accounting\n");
	} else {
		printf("memory_hugetlb_accounting is already enabled\n");
	}

	/* Enable memory controller in subtree */
	fd = open(CGROUP_PATH "/cgroup.subtree_control", O_WRONLY);
	if (fd >= 0) {
		(void)write(fd, "+memory", 7);
		close(fd);
	}

	if (mkdir(TEST_CGROUP_PATH, 0755) != 0) {
		if (errno != EEXIST) {
			perror("mkdir test_reproducer");
			return 1;
		}
	}

	/* Set memory limit to 1MB (less than 2MB hugepage) */
	write_file_val(TEST_CGROUP_PATH "/memory.max", "1M");

	pid = fork();
	if (pid < 0) {
		perror("fork");
		return 1;
	}

	if (pid == 0) {
		/* Child: Move to cgroup */
		write_file_val(TEST_CGROUP_PATH "/cgroup.procs", "0");

		printf("Child: Attempting to allocate and touch 2MB hugepage...\n");
		/* Allocate 2MB hugepage */
		size = 2 * 1024 * 1024;
		addr = mmap(NULL, size, PROT_READ | PROT_WRITE,
			    MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
		if (addr == MAP_FAILED) {
			perror("Child: mmap MAP_HUGETLB");
			exit(1);
		}

		printf("Child: mmap succeeded at %p, touching it now...\n", addr);
		*(char *)addr = 1;

		printf("Child: Successfully touched page (bug not triggered?).\n");
		munmap(addr, size);
		exit(0);
	}

	/* Parent */
	waitpid(pid, &status, 0);

	printf("Parent: Child exited. Cleaning up.\n");
	rmdir(TEST_CGROUP_PATH);

	if (WIFSIGNALED(status)) {
		printf("Parent: Child killed by signal %d (%s)\n",
		       WTERMSIG(status), strsignal(WTERMSIG(status)));
		if (WTERMSIG(status) == SIGBUS)
			printf("Parent: Child got SIGBUS as expected.\n");
	} else if (WIFEXITED(status)) {
		printf("Parent: Child exited with status %d\n", WEXITSTATUS(status));
	}

	return 0;
}

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (2):
      mm: hugetlb: Return -ENOSPC on memcg charge failure
      mm: hugetlb: Drop refcount before freeing on memcg charge failure

 mm/hugetlb.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260901-hugetlb-alloc-folio-memcg-charge-error-handling-5862e632e5f5

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

