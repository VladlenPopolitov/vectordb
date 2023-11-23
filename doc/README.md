# Mathematical algorithms

| Name  | Article authors and title | Year |
| ------------- | ------------- | ----|
| NSW | Yury Malkov , Alexander Ponomarenko , Andrey Logvinov , Vladimir Krylov "Approximate nearest neighbor algorithm based on navigable small world graphs" |2014 |
| HNSW  |Yu. A. Malkov, D. A. Yashunin "Efficient and robust approximate nearest neighbor search using Hierarchical Navigable Small World graphs"  |2016 |
| DiskANN  |Suhas Jayaram Subramanya, Devvrit, Rohan Kadekodi, Ravishankar Krishaswamy, Harsha Vardhan Simhadri, "DiskANN: Fast Accurate Billion-point Nearest Neighbor Search on a Single Node"  |2019 |
| K-NNG |Wei Dong, Moses Charikar, Kai Li "Efficient K-Nearest Neighbor Graph Construction for Generic Similarity Measures" |2011|
|NSG|Cong Fu, Chao Xiang, Changxu Wang, and Deng Cai. Fast approximate nearest neighbor search with the navigating spreading-out graphs.|2019|
|ONNG|Iwasaki, M., Miyazaki, D.: Optimization of Indexing Based on k-Nearest Neighbor Graph for Proximity. arXiv:1810.07355 [pdf](https://arxiv.org/abs/1810.07355) |2018|
|PANNG|Iwasaki, M.: Pruned Bi-directed K-nearest Neighbor Graph for Proximity Search. Proc. of SISAP2016 (2016) 20-33[pdf](https://link.springer.com/chapter/10.1007/978-3-319-46759-7_2)|2016|
|PANNG|Sugawara, K., Kobayashi, H. and Iwasaki, M.: On Approximately Searching for Similar Word Embeddings. Proc. of ACL2016 (2016) 2265-2275 [pdf](https://aclweb.org/anthology/P/P16/P16-1214.pdf)|2016|
|ANNGT|Iwasaki, M.: Applying a Graph-Structured Index to Product Image Search (in Japanese). IIEEJ Journal 42(5) (2013) 633-641 [pdf](https://s.yimg.jp/i/docs/research_lab/articles/miwasaki-iieej-jnl-2013.pdf)|2013|
|ANNGT|Iwasaki, M.: Proximity search using approximate k nearest neighbor graph with a tree structured index (in Japanese). IPSJ Journal 52(2) (2011) 817-828[pdf](https://s.yimg.jp/i/docs/research_lab/articles/miwasaki-ipsj-jnl-2011.pdf)|2011|
|ANNG|Iwasaki, M.: Proximity search in metric spaces using approximate k nearest neighbor graph (in Japanese). IPSJ Trans. on Database 3(1) (2010) 18-28 [pdf](https://s.yimg.jp/i/docs/research_lab/articles/miwasaki-ipsj-tod-2010.pdf)|2010|


# Software
|Name|Algorithm|Link|Language|Index in memory/on disk|Rank|License|
|----|---------|----|--------|-----------------------|----|-------|
|qsgngt|qsgngt, based on NGT-qg、Efanna、SSG|[https://github.com/WPJiang/HWTL_SDU-ANNS](https://github.com/WPJiang/HWTL_SDU-ANNS)|Linux binary lib, Python API|memory|1|?|
|PyNNDescent|K-NNG|[https://github.com/lmcinnes/pynndescent/](https://github.com/lmcinnes/pynndescent/)|Python|memory|1|BSD-2|
|NGT-qg|ONNG,PANNG,ANNGT,ANNG|[https://github.com/yahoojapan/ngt.git](https://github.com/yahoojapan/ngt.git)|C++, interfaces Python, Ruby, PHP, Rust, Go, C|disk|1|Apache-2.0|
|NGT-panng|ONNG,PANNG,ANNGT,ANNG|[https://github.com/yahoojapan/ngt.git](https://github.com/yahoojapan/ngt.git)|C++, interfaces Python, Ruby, PHP, Rust, Go, C|disk|1|Apache-2.0|
|GlassPy|HNSW,Нет документации|[https://pypi.org/project/glassppy/](https://pypi.org/project/glassppy/)|Python library|memory?|1|GPL|
|hnsw(nmslib)|HNSW|[https://github.com/searchivarius/nmslib.git](https://github.com/searchivarius/nmslib.git)|C++, interfaces Python|memory?|1|Apache-2.0|
||||||||
||||||||
||||||||
