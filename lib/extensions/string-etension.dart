extension StringEx on String{
  capitalize(){
    if(isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1,length).toLowerCase()}';
  }
}