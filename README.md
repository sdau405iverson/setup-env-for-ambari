
# setup-env-for-ambari
Use ansible to prepare fund enviroment for ambari 

# 目录结构
```
├── configs
│   ├── disable-thp.service
│   └── vars.yml
├── hosts
│   └── inventory
├── package
│   ├── ambari.repo
│   ├── hdp-2.4.2.0-centos7
│   │   ├── ambari-2.2.2.18-centos7.tar.gz
│   │   ├── HDP-2.4.2.0-centos7-rpm.tar.gz
│   │   └── HDP-UTILS-1.1.0.20-centos7.tar.gz
│   ├── hdp-2.6.2.0-centos7
│   │   ├── ambari-2.5.2.0-centos7.tar.gz
│   │   ├── HDP-2.6.2.0-centos7-rpm.tar.gz
│   │   └── HDP-UTILS-1.1.0.21-centos7.tar.gz
│   ├── hdp.repo
│   ├── hdp-util.repo
│   ├── jdk
│   │   ├── jce_policy-8.zip
│   │   └── jdk-8u131-linux-x64.tar.gz
│   ├── libtirpc-devel
│   │   ├── libtirpc-devel-0.2.4-0.10.el7.x86_64.rpm
│   │   ├── libtirpc-devel-0.2.4-0.6.el7.x86_64.rpm
│   │   ├── libtirpc-devel-0.2.4-0.8.el7.i686.rpm
│   │   └── libtirpc-devel-0.2.4-0.8.el7.x86_64.rpm
│   └── postgresql95
│       ├── postgresql95-9.5.7-1PGDG.rhel7.x86_64.rpm
│       ├── postgresql95-contrib-9.5.7-1PGDG.rhel7.x86_64.rpm
│       ├── postgresql95-devel-9.5.7-1PGDG.rhel7.x86_64.rpm
│       ├── postgresql95-libs-9.5.7-1PGDG.rhel7.x86_64.rpm
│       └── postgresql95-server-9.5.7-1PGDG.rhel7.x86_64.rpm
├── playbooks
│   ├── cluster_start.yml
│   ├── set_env_ol6.yml
│   ├── set_env_ol7.yml
│   └── ssh-addkey.yml
└── README.md
```

# 安装和配置Ansible
1. Install pip
```
sudo apt-get install python-pip
sudo pip install -U setuptools
sudo pip install -U pip
```
2. Install ansible via pip
```
sudo pip install ansible
```
3. Install sshpass
```
sudo apt-get install sshpass
```
4. Set host key checking disabled
```
cat > ~/.ansible.cfg << EOF
[defaults]
host_key_checking = False
EOF
```
# 编辑主机列表文件

setup-env-for-ambari/hosts/inventory

```
[control-node]
192.168.3.181 ansible_ssh_user=samsing  ansible_ssh_pass=samsing timeout=90 ansible_become=yes ansible_become_user=root ansible_become_pass=redhat ansible_become_method=su ansible_become_flags='-'

[manage-node]
192.168.3.182 ansible_ssh_user=samsing  ansible_ssh_pass=samsing timeout=90 ansible_become=yes ansible_become_user=root ansible_become_pass=redhat ansible_become_method=su ansible_become_flags='-'
192.168.3.183 ansible_ssh_user=samsing  ansible_ssh_pass=samsing timeout=90 ansible_become=yes ansible_become_user=root ansible_become_pass=redhat ansible_become_method=su ansible_become_flags='-'

[data-node]
192.168.3.182 ansible_ssh_user=samsing  ansible_ssh_pass=samsing timeout=90 ansible_become=yes ansible_become_user=root ansible_become_pass=redhat ansible_become_method=su ansible_become_flags='-'
192.168.3.183 ansible_ssh_user=samsing  ansible_ssh_pass=samsing timeout=90 ansible_become=yes ansible_become_user=root ansible_become_pass=redhat ansible_become_method=su ansible_become_flags='-'
```

[control-node]表示一个组

ansible_ssh_user=samsing 表示使用用户samsing连接

ansible_ssh_pass=samsing 表示连接使用的密码

timeout=90 连接超时时间

如果目标主机不允许使用root用户进行连接的话需要添加如下配置：

ansible_become=yes 

ansible_become_user=root 

ansible_become_pass=redhat 

ansible_become_method=su 

ansible_become_flags='-'

**一定记得根据实际环境情况对ip及用户信息进行相应的修改**

# 编辑变量文件

setup-env-for-ambari/configs/vars.yml

    net_work: 10.2.211.0
    net_mask: 255.255.255.0
    
    hostname_vars:
      - ip: 192.168.3.181
        hostname_long: auto-cn-01.embrace.com
        hostname_short: auto-cn-01
    
      - ip: 192.168.3.182
        hostname_long: auto-nn-01.embrace.com
        hostname_short: auto-nn-01
    
      - ip: 192.168.3.183
        hostname_long: auto-nn-02.embrace.com
        hostname_short: auto-nn-02
    

主要是修改内容:

1. net_work
2. net_mask
3. hostname_vars
   该变量主要用于配置/etc/hosts文件
         - ip: 192.168.3.181
           hostname_long: auto-cn-01.embrace.com
           hostname_short: auto-cn-01
       
   对应/etc/hosts中的一个条目： 192.168.3.181 auto-cn-01.embrace.com auto-cn-01


# 脚本使用方法及简介

1. 使用方法

```
cd setup-env-for-ambari
ansible-playbook -i hosts/inventory playbooks/set_env_ol7.yml
```

2.playbook简介

playbook使用yaml格式。

一个palybook可以对应多个play,一个play可以对应操作多个host,同时一个play包含多个task,一个task操作一个moduel。

```
---
- name: close firewall,selinux; modify hostname
  hosts: all #执行tasks的主机
  vars_files: #引用变量文件
    - ../configs/vars.yml  
  tasks:   # task列表
    - name: close firewall #task名称
      service: #task所使用的module
        name: firewalld
        state: stopped
        enabled: no

    - name: close selinux temporarily
      shell: setenforce 0
      ignore_errors: yes

    - name: colse selinux Permanently
      lineinfile:
        dest: /etc/selinux/config
        regexp: 'SELINUX='
        line: 'SELINUX=disabled'

    - name: modify hostname
      hostname:
        name: "{{ item['hostname_short'] }}"
      with_items: "{{ hostname_vars }}" #loop
      when: inventory_hostname == item['ip'] #condition

    - name: modify /etc/hosts
      lineinfile:
        dest: /etc/hosts
        regexp: "{{ item['ip'] }}"
        line: "{{ item['ip'] }} {{ item['hostname_long'] }} {{ item['hostname_short'] }}"
        state: present
      with_items: "{{ hostname_vars }}"
```

