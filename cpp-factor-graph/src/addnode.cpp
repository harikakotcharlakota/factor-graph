#include "addnode.h"

#include "matrix.h"

bool AddNode::isSupported(Message::Type type)
{
    return type == GaussianMessage::GAUSSIAN_VARIANCE;
}


void AddNode::addOutgoing(FactorNode *node)
{
    assert(m_outgoing.size() == 0);
    FactorNode::addOutgoing(node);
}


GaussianMessage AddNode::function(int to, const MessageBox &msgs)
{
    assert(!msgs.empty());
    assert(isForward(to) || isBackward(to));
    assert(m_outgoing.size() == 1);

    return isForward(to) ? forwardFunction(to, msgs) : backwardFunction(to, msgs);
}




GaussianMessage AddNode::forwardFunction(int to, const MessageBox &msgs)
{
    size_t size = msgs.begin()->second.size();
    size_t size2 = size * size;

    GaussianMessage result(size);
    double *median = result.mean();
    double *variance = result.variance();

    for (auto it = m_incoming.begin(); it != m_incoming.end(); ++it)
    {
        const GaussianMessage &msg = msgs.at(*it);
        transform(msg.mean(), msg.mean() + size, median, median, std::plus<double>());
        transform(msg.variance(), msg.variance() + size2, variance, variance, std::plus<double>());
    }

    return result;
}

GaussianMessage AddNode::backwardFunction(int to, const MessageBox &msgs)
{
    size_t size = msgs.begin()->second.size();
    size_t size2 = size * size;

    GaussianMessage result(size);
    double *median = result.mean();
    double *variance = result.variance();

    const GaussianMessage &outMsg = msgs.at(*m_outgoing.begin());
    transform(outMsg.mean(), outMsg.mean() + size, median, median, std::plus<double>());
    transform(outMsg.variance(), outMsg.variance() + size2, variance, variance, std::plus<double>());

    for (auto it = m_incoming.begin(); it != m_incoming.end(); ++it)
    {
        if (*it == to)
            continue;
        const GaussianMessage &msg = msgs.at(*it);
        transform(median, median + size, msg.mean(), median, std::minus<double>());
        transform(msg.variance(), msg.variance() + size2, variance, variance, std::plus<double>());
    }

    return result;
}








