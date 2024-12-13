extension MapExtensions<K, V> on Map<K, V> {
  Map<K, V> put(K key, V value) {
    update(key, (_) => value,ifAbsent: () => value);
    return this;
  }

  Map<K,V> clone({MapEntry<K,V>? withh}){
    final Map<K,V> clone=Map.from(this);
    if(withh!=null) clone.put(withh.key,withh.value);
    return clone;
  }
}