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
|FLANN|Marius Muja and David G. Lowe, "Fast Approximate Nearest Neighbors with Automatic Algorithm Configuration", in International Conference on Computer Vision Theory and Applications (VISAPP'09) [pdf](https://www.cs.ubc.ca/research/flann/uploads/FLANN/flann_visapp09.pdf)|2009|
|PQ|“Product quantization for nearest neighbor search”, Jégou & al., PAMI [pdf](https://inria.hal.science/inria-00514462v2/document)|2011|
|Optimized PQ| “Optimized product quantization”, He & al, CVPR [pdf](http://ieeexplore.ieee.org/abstract/document/6678503/)|2013|
|GPU| “Billion-scale similarity search with GPUs”, Johnson & al, ArXiv 1702.08734 [pdf](https://arxiv.org/abs/1702.08734)|2017|
|AH|Ruiqi Guo, Philip Sun, Erik Lindgren, Quan Geng, David Simcha, Felix Chern, and Sanjiv Kumar, Accelerating Large-Scale Inference with Anisotropic Vector Quantization [pdf](https://arxiv.org/pdf/1908.10396.pdf)|2019|


# Software
|Name|Algorithm|Link|Language|Index in memory/on disk|Rank|License|
|----|---------|----|--------|-----------------------|----|-------|
|qsgngt|qsgngt, based on NGT-qg、Efanna、SSG|[https://github.com/WPJiang/HWTL_SDU-ANNS](https://github.com/WPJiang/HWTL_SDU-ANNS)|Linux binary lib, Python API|memory|1|?|
|PyNNDescent|K-NNG|[https://github.com/lmcinnes/pynndescent/](https://github.com/lmcinnes/pynndescent/)|Python|memory|1|BSD-2|
|NGT-qg|ONNG,PANNG,ANNGT,ANNG|[https://github.com/yahoojapan/ngt.git](https://github.com/yahoojapan/ngt.git)|C++, interfaces Python, Ruby, PHP, Rust, Go, C|disk|1|Apache-2.0|
|NGT-panng|PANNG|[https://github.com/yahoojapan/ngt.git](https://github.com/yahoojapan/ngt.git)|C++, interfaces Python, Ruby, PHP, Rust, Go, C|disk|1|Apache-2.0|
|GlassPy|HNSW,NSG|[https://github.com/zilliztech/pyglass](https://github.com/zilliztech/pyglass)|C++ (Python library)|memory|1|GPL|
|hnsw(nmslib)|HNSW|[https://github.com/searchivarius/nmslib.git](https://github.com/searchivarius/nmslib.git)|C++, interfaces Python|memory?|1|Apache-2.0|
|NGT-ONNG|ONNG|[https://github.com/yahoojapan/ngt.git](https://github.com/yahoojapan/ngt.git)|C++, interfaces Python, Ruby, PHP, Rust, Go, C|disk|2|Apache-2.0|
|ScaNN||[https://github.com/google-research/google-research/tree/master/scann](https://github.com/google-research/google-research/tree/master/scann)|C++, Python interface, (Tensorflow required)|memory?|2|Apache-2.0|
|Milvus(knowhere)|HNSW, FAISS|[https://github.com/milvus-io/knowhere](https://github.com/milvus-io/knowhere) или [https://github.com/zilliztech/Knowhere](https://github.com/zilliztech/Knowhere)|C++, Python interface|memory?|2|Apache-2.0|
|DiskANN(vamana)|DiskANN|[https://github.com/microsoft/diskann](https://github.com/microsoft/diskann)|C++, interfaces Python|disk|2|MIT|
|vearch|HNSW,IVFFLAT,FLAT,BINARYIVF,IVFPQ,GPU|[https://github.com/vearch/vearch](https://github.com/vearch/vearch)|C++, Python interface, (Golang)|disk|2|Apache-2.0|
|hnsqlib|HNSW|[https://github.com/nmslib/hnsw.git](https://github.com/nmslib/hnsw.git)|C++, Python interface||2|Apache-2.0|
|flann|FLANN|[https://github.com/mariusmuja/flann](https://github.com/mariusmuja/flann)|C++, interfaces C, MATLAB, Python, and Ruby|memory|3|BSD|
|faiss-ivfpqfs|HNSW,PQ,GPU|[https://github.com/facebookresearch/faiss](https://github.com/facebookresearch/faiss)|C++, Python interface||3|MIT|

# Methods and articles
![Articles on methods](https://raw.githubusercontent.com/wiki/facebookresearch/faiss/PQ_variants_Faiss_annotated.png)