
For reproducibility, it is needed the *r-base* installed. In the debian/ubuntu plataform, you can run the command in terminal:

```
$ sudo apt-get install r-base
```

After in the prompt, install the dependencies:

```
$ R -e 'install.packages(c("data.table", "tidyverse", "lubridate", "ggplot2"))'
```

Unfortunately it is not all reproducible, since it would need the data files: `pdpviews-Dez05-sample.ndjson`, `pdpviews-Dez06-sample.ndjson` and `transactions-Dez07.ndjson` in `./data` directory. But imagining that theses file are present, thus the steps would be:

Run the training, inside the `src/` folder, execute:

```
$ Rscript training.R
```

After a long running it will save the *best model* in `src/cache/dummy-profiles.rds`, which will be read by main.R to create the outputs.

```
$ Rscript main.R
```

