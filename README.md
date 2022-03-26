# cloud-cli-helpers
helper functions to use the CLI for aws, linode, digital ocean.


### Installation

#### prerequisites:
* Install the following CLI:
  * [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  * [digital ocean cli](https://docs.digitalocean.com/reference/doctl/how-to/install/)
  * [linode cli](https://www.linode.com/community/questions/18861/how-do-i-install-the-linode-cli)
* configure each provider that you would like to use according to the instrucions in their docs

#### Install:
* clone this repo
* edit `user_variables.dummy`, update the variables, and rename to `user_variables.private`
  * for digital ocean `dropshortnames` is a key for a part of the name of the instance. You should always use the same key when creating instances. A good practice is to use your initials i.e. `ctw`. This key will be used to list _and remove_ all instances in your digital ocean setup with that key, so make sure that key is unique to you.
  * for aws, the `aws_name` and `aws_initials` are equivalent to `dropshortnames` for digital ocean. All instances with these keys in the name/tag will be removed, so be sure they are unique to you.
* in `cli-helpers.sh`, ensure that line 1 points to your local `user_variables.private` file
* edit your shell's config file (~/.oh-my-zsh, or ~/.profile depending on your setup)
  * add `source <path_to_cloned_repo>/cli-helpers.sh` to your shell's config file
* open a new shell, and confirm that you can run `drop-list`

### How to Use
naming is fairly straightforward, but here is a rundown:
* *-list will list all instances with your specified key
  * for aws, this can take up to 1 argument, the region you'd like to list
* *-create will create an instance with the name you specify as the first argument in your default region (specified in `user_variables.private`)
  * for aws, this can take 1 additional argument, the region to create the instance in
* *-delete takes 1 argument, the instance you wish to delete
  * for aws, this can take 1 additional argument, the region to delete the instance from
* *-remove-all removes all instances with your tag(s) from the specified provider
  * for aws, this can take 1 additional argument, the region to delete the instances from
