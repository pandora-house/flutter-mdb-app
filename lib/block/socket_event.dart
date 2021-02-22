abstract class SocketEvent {}

class ConnectEvent extends SocketEvent {}

class DisconnectEvent extends SocketEvent {}

class InitEvent extends SocketEvent {}