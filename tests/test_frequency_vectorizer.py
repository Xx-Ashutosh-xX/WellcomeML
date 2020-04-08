# encoding: utf-8
from wellcomeml.ml import WellcomeTfidf


def test_tf_idf_dispatch():
    X = ['Sentence Lacking Stopwords']

    text_vectorizer = WellcomeTfidf()
    X_embed = text_vectorizer.fit_transform(X)

    assert (X_embed.shape == (1, 3))


def test_save_and_load(tmpdir):
    tmpfile = tmpdir.join('test.npy')

    X = ["This is a sentence"*100]

    vec = WellcomeTfidf()

    X_embed = vec.fit_transform(X)

    vec.save_transformed(str(tmpfile), X_embed)

    X_loaded = vec.load_transformed(str(tmpfile))

    assert (X_loaded != X_embed).sum() == 0
